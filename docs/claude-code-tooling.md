# Claude Code — code-intelligence tooling

This document records the Nix-managed setup that gives Claude Code structural awareness
of Rust + Swift projects on this machine, plus the verification steps and the next
layer (graph tooling) that has been deliberately deferred.

Everything described here is reproduced on every `hs` (i.e. `darwin-rebuild switch
--flake ~/.config/nix`). Nothing is installed imperatively.

## What's set up

### 1. Native LSP — rust-analyzer + sourcekit-lsp

Claude Code's built-in LSP tool reads `~/.claude/.lsp.json` and starts the language
servers listed there. The file is materialised by home-manager from
`modules/home-manager/settings/claude.nix`:

- `rust` → `${pkgs.rust-analyzer}/bin/rust-analyzer` for `*.rs`
- `swift` → `${pkgs.sourcekit-lsp}/bin/sourcekit-lsp` for `*.swift`

Both commands are absolute Nix store paths, so they survive `$PATH` changes and are
recreated atomically on every rebuild. `sourcekit-lsp` and `rust-analyzer` are also in
`home.packages` so they show up in `$PATH` for ad-hoc use.

No `ENABLE_LSP_TOOL` environment variable, no plugin install: current Claude Code
treats `.lsp.json` as the only signal needed.

### 2. Repomix — `unstable.repomix` (1.14.x) + `repomix-skeleton` wrapper

`repomix` is installed from `nixpkgs-unstable` (same channel `claude-code` and `devenv`
come from). A small wrapper `repomix-skeleton` is provided to standardise the
"signatures-only structural overview" invocation:

```
repomix-skeleton [path]          # default: cwd
```

…writes `<path>/.repomix/skeleton.md`, using `--compress` so the output is class /
function / interface signatures only (tree-sitter parsing, bodies stripped).

The wrapper is defined in `modules/home-manager/settings/packages.nix` as a
`pkgs.writeShellScriptBin` and exposed via `home.packages`.

## How to use it on a target project

Add a `repomix.config.json` to the target repo root that excludes generated paths:

```json
{
  "ignore": {
    "customPatterns": [
      "target/**",
      ".build/**",
      "DerivedData/**",
      "node_modules/**",
      "dist/**",
      ".repomix/**"
    ]
  }
}
```

Add a `justfile` with a recipe per component:

```just
skeleton-client:
    repomix-skeleton client

skeleton-server:
    repomix-skeleton server

skeleton-tui:
    repomix-skeleton tui

skeleton-all: skeleton-client skeleton-server skeleton-tui
```

Add `.repomix/` to the project's `.gitignore`. Hand the per-component skeleton files to
Claude Code at the start of a session when you want it to plan against the whole
architecture rather than only what it can see in its current file open.

## Verification

After `hs`:

1. **LSP config emitted, references store paths:**
   ```
   cat ~/.claude/.lsp.json
   ```
   Both `command` values should be `/nix/store/...`.

2. **Servers actually run:**
   ```
   "$(jq -r '.rust.command' ~/.claude/.lsp.json)" --version
   "$(jq -r '.swift.command' ~/.claude/.lsp.json)" --help | head
   ```

3. **Claude Code is using LSP, not text search.** In a Claude Code session opened in a
   Rust or Swift project, ask it to find references to a symbol that is defined in one
   file and used from several. Watch the tool-call stream — the `LSP` tool name should
   appear. If Claude is falling back to `Grep` / `Read`, something is wrong with
   `.lsp.json` discovery.

4. **Repomix runs:**
   ```
   repomix --version          # expect 1.14.x
   cd <target-project>
   repomix-skeleton server
   head -40 server/.repomix/skeleton.md
   ```
   Output should be signatures only — function names, struct fields, no bodies.

5. **No imperative residue:** `git status` in `~/.config/nix` and `~/.claude/` should
   show only what was intentionally changed.

## Known caveats

- **sourcekit-lsp + macOS toolchain discovery.** `pkgs.sourcekit-lsp` 5.10.1 relies on
  `xcrun` finding a usable Swift toolchain at runtime. If LSP returns "no such module"
  errors on `.swift` files, the recovery is one of:
  - Set `SDKROOT` via `home.sessionVariables`, or
  - Wrap the binary with `pkgs.writeShellScriptBin` that prepends `xcrun` and reference
    the wrapper in `.lsp.json`'s `command`.
  Both stay declarative.

## How to extend

- **Adding another language server.** Add an entry to the `lspServers` let-binding in
  `modules/home-manager/settings/claude.nix`; the file is regenerated on next rebuild.
- **Picking up `lspServers` as a real module option.** When the home-manager flake input
  is bumped past `release-25.11` to a release that includes the `programs.claude-code.
  lspServers` option, the `let`-binding + `home.file` line can be swapped for the
  module option. The schema is identical (`command`, `args`, `extensionToLanguage`).
- **Adding more Repomix wrappers.** Define another `pkgs.writeShellScriptBin` in
  `packages.nix` alongside `repomix-skeleton`. Avoid putting target-project paths into
  the global nix config — keep those in the project's `justfile`.

## Deferred: graph-based code intelligence

Not installed in this pass. What it would add over LSP + Repomix:

- **Cross-language call graphs** — e.g. a Swift caller invoking a Rust-FFI symbol,
  which neither rust-analyzer nor sourcekit-lsp can follow alone.
- **Reverse-dependency queries** across all three components at once ("who calls X?",
  "what trait impls does this break?").
- **Whole-repo semantic impact analysis** that doesn't fit in a single LSP request.

Candidates for a Rust + Swift repo:

- **GitNexus** — Tree-sitter multi-language indexer with an MCP server. Strong fit on
  the technical axis, but licensed **PolyForm Noncommercial** — eligibility depends on
  whether the target project is commercial. Do not adopt without a license decision.
- **codegraph-rust** — Rust-focused, weaker Swift coverage. Probably insufficient on
  its own for this stack.
- **scip + Sourcegraph self-hosted** — Heavier infra (scip-rust + scip-clang + a
  Sourcegraph instance). Full-power, but overkill for a single repo.

Decision point: only revisit after a couple of weeks of using LSP + Repomix. If Claude
is consistently missing cross-component context that LSP can't see (especially across
the Swift⇄Rust boundary), and the target project's license posture allows it, GitNexus
is the first thing to try.
