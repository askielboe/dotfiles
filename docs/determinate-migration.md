# Determinate Nix migration (parallel evaluation)

**Status: staged, NOT applied.** This is a runbook. The config changes below are
*not* in the live flake — applying `determinateNix.enable = true` on a
non-Determinate system would strip nix-darwin's Nix management (flakes,
experimental-features) while Determinate isn't there to replace it, i.e. it can
break your Nix. Do the teardown/install steps **first**, then apply the diff.

## Why

`hs` spends ~30 s single-threaded in *evaluation* before any build; profiling
(2026-07) showed ~14 s of that (~60%) is nixvim codegen-ing the Neovim config
through the module system every run. Nix's evaluator is single-threaded and
there is **no upstream flag** to parallelise it — the multithreaded evaluator
was built by Determinate Systems and ships **only in Determinate Nix** (3.11+;
defaults to all cores since 3.16). This machine has 10 cores (8P+2E), so
`eval-cores = 0` can fan that eval out ~10 ways. Expected: ~30 s → ~10–12 s.

Weigh this against the cost (full teardown, see below) and the community
politics around Determinate (see the repo discussion / LWN 981124). This is a
personal-machine speedup, fully reversible, but not free. `nh` (already applied)
improved the *loop* without any of this.

## The catch: this is a teardown, not an upgrade

- The Determinate installer **refuses to run if it detects nix-darwin**. There is
  no in-place `determinate-nixd upgrade` from a vanilla install.
- This machine's Nix is the **official installer** (`org.nixos.*` LaunchDaemons,
  no `/nix/nix-installer` binary, no `/nix/receipt.json`), so there's **no clean
  DS uninstall receipt** — the Nix uninstall is the manual/official path.
- Net sequence: uninstall nix-darwin → uninstall Nix → install Determinate Nix →
  re-bootstrap nix-darwin with the module below.

Budget an hour and don't do it right before you need the machine.

## Steps (run manually — do not let an agent run these)

1. **Commit everything** in this repo and make sure nothing important lives only
   in `/nix/store` (dev shells, GC roots you care about).
2. **Uninstall nix-darwin.** Use nix-darwin's own uninstaller — see
   <https://github.com/nix-darwin/nix-darwin#uninstalling>. (Known finicky on
   darwin: DeterminateSystems/nix-installer#607.)
3. **Uninstall Nix (official installer).** Follow the upstream manual uninstall
   for macOS multi-user: <https://nix.dev/manual/nix/latest/installation/uninstall>
   (removes `/nix`, the `org.nixos.*` daemons, `_nixbld*` users/group, and the
   shell hooks). The `/nix/store` itself can be kept to avoid a full re-download.
4. **Install Determinate Nix.** Use the macOS **graphical package** from
   <https://determinate.systems/> (the DS-recommended macOS path; the CLI form is
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate`).
   Follow the current official page for the exact command.
5. **Apply the config diff below**, then **re-bootstrap nix-darwin**:
   `sudo nix run nix-darwin -- switch --flake ~/.config/nix#askielboe --impure`
   (first time; `hs` works thereafter).
6. **Verify:**
   - `nix config show | grep eval-cores`  → should be non-empty (0 / 10).
   - Re-time: `time nix eval --impure --raw '.#darwinConfigurations.askielboe.system.drvPath'`
     and watch the nixvim segment
     (`.config.home-manager.users.askielboe.programs.nixvim.build.package.drvPath`)
     drop from ~14 s.

## Config diff to apply (step 5)

### `flake.nix` — add the input

```nix
# Determinate Nix: multithreaded evaluator + lazy-trees. OWNS the Nix install
# (determinateNix.enable disables nix-darwin's Nix management), replacing the
# `nix = { ... }` block in modules/darwin/default.nix.
determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
```

### `flake.nix` — add the darwin module

In `darwinConfigurations.${user}` → `modules = [ ... ]`, add:

```nix
inputs.determinate.darwinModules.default
```

(`inputs` is already in scope via the `inputs@{ ... }` output pattern.)

### `modules/darwin/default.nix` — swap the `nix` block

Replace:

```nix
nix = {
  gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };
  optimise = {
    automatic = true;
  };
  settings = {
    experimental-features = "nix-command flakes";
  };
};
```

with:

```nix
# Nix itself is managed by Determinate (see the `determinate` input + module in
# flake.nix), NOT nix-darwin. `determinateNix.enable` disables nix-darwin's Nix
# management; settings below are written to /etc/nix/nix.custom.conf.
determinateNix.enable = true;
determinateNix.customSettings = {
  # The point of the migration: parallel evaluation across all 10 cores.
  # 0 = all cores. (Determinate 3.16+ already defaults to unlimited; explicit.)
  eval-cores = 0;
  # Preserve the old nix.optimise.automatic (hardlink dedup on each store add).
  auto-optimise-store = true;
};
```

Notes:
- **Don't** set `experimental-features` here — Determinate enables
  `nix-command`/`flakes` by default, and overriding would drop its other defaults.
  Use `extra-experimental-features` if you ever need to *add* one.
- **Garbage collection** moves from nix-darwin's weekly `--delete-older-than 7d`
  to `determinate-nixd`'s automatic (free-space-based) GC. To keep an explicit
  policy instead, configure `determinateNixd.garbageCollector` — see the DS
  nix-darwin module docs. (Heads-up: `firewall-prune.nix` has a comment assuming
  the weekly nix-darwin GC cadence; harmless, but the timing assumption changes.)
- `ids.gids.nixbld = 350;` — **revisit after migration.** Determinate manages
  build users itself; this nix-darwin macOS-15 workaround may be redundant or
  conflict. Verify a build works, then drop it if unneeded.
- `lazy-trees` is on by default in current Determinate (stops copying the whole
  flake — incl. the ~60 nixvim files — into the store each eval). No action needed.

## Rollback

Revert the commit that applies the diff, reinstall upstream Nix
(<https://nixos.org/download/>), re-bootstrap nix-darwin. The `/nix/store`
survives; you lose parallel eval and go back to ~30 s.
