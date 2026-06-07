# Nix Configuration

## Initial Setup

Before building, you must create your private configuration file:

```bash
cp secrets/private.example.nix secrets/private.nix
```

Then edit `secrets/private.nix` with your personal values:
- `user.name` - Your full name (for git commits)
- `user.email` - Your email address
- `user.username` - Your system username
- `user.homeDirectory` - Your home directory path
- `user.signingKey` - Your SSH signing key (optional)
- `accounts.opAccount` - Your 1Password account ID
- `accounts.awsProfiles` - Your AWS profile configurations
- `machine.computerName` - Your machine hostname
- `ssh.*` - Your SSH host configurations

This file is gitignored and contains your personal/sensitive information.

## macOS Setup

1. Clone this repo to `~/.config/nix`
2. Create private config (see above)
3. Install `nix`
4. Build and switch:
   ```bash
   ./build-and-switch-darwin.sh
   ```

Alternative manual steps:
```bash
nix --extra-experimental-features "nix-command flakes" build '.#darwinConfigurations.<username>.system'
./result/sw/bin/darwin-rebuild switch --flake ~/.config/nix/'.#<username>'
```

## Ubuntu/Linux Setup

1. Clone this repo to `~/.config/nix`
2. Create private config (see above)
3. Install `nix`
4. Install `home-manager`
5. Build and switch:
   ```bash
   ./build-and-switch-linux.sh
   ```

Alternative manual steps:
```bash
nix --extra-experimental-features "nix-command flakes" build '.#homeConfigurations.<username>.activationPackage'
./result/activate
```

## ActivityWatch (macOS)

ActivityWatch is installed declaratively as a Homebrew cask
(`activitywatch@beta`, the native arm64 build) and launched at login by a
launchd user agent — both defined in `modules/darwin/settings/activitywatch.nix`.
After a rebuild it tracks active window + idle time; `aw-server` answers on
<http://localhost:5600>.

### One-time manual step: Accessibility permission

`aw-watcher-window` can only read window **titles** (not just app names) once
ActivityWatch has the Accessibility permission, and keyword categorization relies
on titles. This grant cannot be set declaratively — do it once:

1. **System Settings → Privacy & Security → Accessibility**
2. Enable **ActivityWatch** (and approve the terminal app if macOS prompts).

After granting, restart ActivityWatch (or reboot). Verify by checking that the
`aw-watcher-window` bucket at <http://localhost:5600> shows real window titles.

### Categorization rules

The category ruleset is version-controlled at `activitywatch/categories.json`.
ActivityWatch has no startup file-seeding for categories, so importing is a
manual UI step (the JSON file stays the source of truth in this repo):

1. Open <http://localhost:5600> → **Settings → Categorization**.
2. Click **Import** and choose `activitywatch/categories.json`.
3. Click **Save**.

The file uses ActivityWatch's legacy `{ "categories": [...] }` import format
(rules are case-insensitive regex matched against app name + window title). After
editing categories in the UI, click **Export** and overwrite the repo file to
keep it authoritative.

### Extra watchers

Beyond the bundled window/AFK watchers:

- **Editor (`aw-watcher-vim`)** — installed declaratively into Neovim via
  `modules/home-manager/nixvim/plugins/aw-watcher-vim/`. It auto-starts on launch
  and reports the edited file + language to `aw-server` (an
  `aw-watcher-vim_<host>` bucket appears at <http://localhost:5600>). Nothing to
  do beyond rebuilding; `:AWStatus` inside nvim confirms it's connected.

- **Browser (`aw-watcher-web`)** — **manual, per-browser**. This is a browser
  extension, and your browsers are Homebrew casks (not home-manager-managed), so
  it can't be installed declaratively. Install "ActivityWatch Web Watcher" from
  each browser's add-on store (Firefox: addons.mozilla.org; ungoogled-chromium:
  Chrome Web Store / sideload). It talks to `aw-server` on `5600` and creates an
  `aw-watcher-web-<browser>` bucket. This gives per-tab URL/domain data, which is
  more reliable than the page title alone for categorizing web work.

### Proposed follow-up (not applied): richer terminal titles

Terminal work is keyword-categorized off the terminal **window title**. The
current setup already puts the working directory in the title — prezto's
`terminal` module (enabled in `modules/home-manager/settings/shell.nix`) sets the
window title to the abbreviated `cwd` on each prompt (and the running command
during execution), and Ghostty (`shell-integration = detect`, no static `title`)
passes that through. So no shell change is required for cwd-based categorization.

If you later want git-repo/branch-aware titles for finer rules, the minimal
change would be a zsh `precmd` emitting an OSC-2 title that includes the repo
name — kept as a separate, opt-in change to avoid touching shell config here.

## Secrets (SOPS)

For runtime secrets (not nix eval-time), use sops:

```bash
cd modules/sops
sops secrets/restic.yaml
```

Based on https://github.com/lanjoni/snowflake.
