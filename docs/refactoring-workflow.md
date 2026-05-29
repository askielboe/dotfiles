# Disciplined refactoring workflow for Claude Code

This document describes the `/refactor` workflow: an advisory, user-invoked path for
structural and multi-file refactors. It is **not** enforced — no process-level hook
blocks edits. The aim is to make the good path (map → propose → stop for selection →
implement) the easiest one to reach for.

## 1. Why this exists

Claude Code is very good at locally-correct edits. The repeated failure mode is the
*globally-wrong* edit: a change that compiles, type-checks, even passes tests, but cuts
across an architectural seam in a way that nobody asked for. By the time you read the
diff, the new shape is already chosen.

The fix is a *stop*. Before any edit, take one explicit pass to (a) understand the blast
radius and (b) consider 2–3 structurally distinct ways the refactor could go. The user
picks. Then implement.

`/refactor` is the one-keystroke entry to that flow.

## 2. The three layers

```
~/.claude/skills/refactor/SKILL.md          ← Layer 1: the playbook + slash command
~/.claude/agents/refactor-mapper.md         ← Layer 2: read-only mapper subagent
~/.claude/CLAUDE.md                         ← Layer 3: advisory nudge
```

All three are declared in this repo's Nix config under
`modules/home-manager/settings/claude-assets/`, wired through `programs.claude-code` in
`modules/home-manager/settings/claude.nix`:

```nix
skills = {
  using-agent-skills = "${addy-skills}/skills/using-agent-skills";
  refactor = ./claude-assets/skills/refactor;
};

agents = {
  refactor-mapper = ./claude-assets/agents/refactor-mapper.md;
};

memory.source = ./claude-assets/memory.md;
```

Each home-manager rebuild (`hs`) symlinks them into `~/.claude/`.

### Layer 1 — the `/refactor` skill

A skill at `~/.claude/skills/refactor/SKILL.md`. Invocable two ways:

- **Explicit**: type `/refactor` in any Claude Code session.
- **Autonomous**: Claude may auto-invoke when the description matches (structural /
  multi-file refactoring). The description deliberately excludes single-file bug fixes.

The skill body is the contract. It has six steps; **step 5 — STOP and wait for the
user's selection** is the load-bearing one. The body explicitly forbids defaulting to
option 1 or proposing "I'll start unless you object."

### Layer 2 — `refactor-mapper` read-only subagent

A subagent at `~/.claude/agents/refactor-mapper.md` with `tools: Read, Grep, Glob` as
its allowlist. **No Edit, no Write, no Bash.** This is the security boundary: the
subagent cannot mutate the filesystem regardless of what its body says. The parent skill
takes the mapper's returned text and writes the map file itself.

If the target spans Rust + Swift, the mapper runs two parallel passes (one per
language) and reconciles at the FFI/bridge boundary.

### Layer 3 — global `CLAUDE.md` nudge

A short section in `~/.claude/CLAUDE.md` pointing future Claude sessions at `/refactor`
for structural changes and at **plan mode (Shift+Tab)** as the hard floor available
when the user wants edits locked until a plan is approved.

## 3. Daily use

Type `/refactor` in a Claude Code session, then describe the target. The flow:

1. Claude restates the target in one sentence (and asks if it's ambiguous).
2. The `refactor-mapper` subagent runs read-only and returns a structured map.
3. The parent writes the map to
   `.claude/refactor-maps/<ISO-timestamp>-<slug>.md` in the current project.
4. Claude presents 2–3 distinct proposals (each with: what changes, blast radius,
   tradeoff, what could break).
5. Claude stops on the literal line:
   `Awaiting your selection (1 / 2 / 3) before any edits.`
6. You reply with a number. Claude creates a `refactor/<slug>` branch and implements
   narrowly. Any drift from the chosen proposal is surfaced back to you instead of
   silently expanding scope.

**To abort mid-flow**: just say so at any pause point. Nothing is committed until you
approve at step 6 and Claude has executed.

## 4. Plan mode as the hard floor

`/refactor` is *advisory*. The mapper subagent is read-only, but nothing prevents you
from directly typing "rename foo to bar across these 12 files" and bypassing the skill
entirely.

When you want a real lock — no edits at all until you approve — use **plan mode**:
press **Shift+Tab** in Claude Code. Plan mode is a process-level constraint: Claude
can only read and write to the plan file until you exit. Use it for:

- High-risk refactors crossing shared infrastructure
- Refactors that touch other people's code paths
- Anything where you want to review the *intent* in writing before any code moves

Contrast with `/refactor`: the skill makes the propose→select step the *easy* path;
plan mode makes it the *only* path. Reach for plan mode when easy isn't enough.

## 5. Extending the workflow

The source files live in `modules/home-manager/settings/claude-assets/`. Common tweaks:

- **Add a language-specific mapper rule**: edit `agents/refactor-mapper.md` step 3
  ("Note language-specific structure"). Add a bullet for the new language.
- **Adjust proposal count**: edit `skills/refactor/SKILL.md` step 4. The skill currently
  requires 2–3 distinct options and forbids padding.
- **Swap the mapper's model**: change `model: sonnet` in
  `agents/refactor-mapper.md` frontmatter (haiku for speed, opus for accuracy on large
  codebases).
- **Tighten the mapper's tools further**: the allowlist is `Read, Grep, Glob`. If a new
  Claude Code release adds a read-only file inspection tool, add it here.

After any edit, run `hs` to rebuild. The new content is live on the next Claude Code
session.

## 6. Graph tooling — proposed, not built

The mapper currently uses LSP-grounded edges (rust-analyzer + sourcekit-lsp, wired
through `~/.claude/.lsp.json`) where available and `Grep` otherwise. For most
refactors this is enough. If accuracy gaps in cross-language refactors start biting,
here is where a graph tool would plug in.

### Plug point in `refactor-mapper.md`

In the mapper's procedure, between step 2 ("Traverse outward") and the "Output format"
section. The graph would feed sections 3 (Inbound edges) and 4 (Outbound edges) with
precise, queried results instead of grep-derived best-effort.

### Per-language recommendations

- **Rust**: rust-analyzer's symbol/reference APIs (already wired via `.lsp.json`) give
  accurate call-graph edges for free. Use first. No additional install.
- **Swift**: sourcekit-lsp gives equivalent edges via the same `.lsp.json` wiring. Use
  first. No additional install.

### Polyglot graph candidates (Rust + Swift unified)

If you need a unified graph spanning both languages (rare — usually two parallel passes
reconciled at the FFI boundary works), two candidates:

- **codegraph-rust** — MIT-licensed. Single-language focus per crate. Lower-effort
  integration for Rust-only blast-radius queries. Picks: if your refactors are
  predominantly Rust and Swift is a thin shell.

- **GitNexus** — broader polyglot graph DB, designed for cross-language traversal.
  **License caveat**: PolyForm Noncommercial. Eligibility depends on commercial status.
  For commercial work (e.g. mrssporty / Toustrup), this likely disqualifies it — read
  the license at https://polyformproject.org/licenses/noncommercial/1.0.0/ and confirm
  before installing.

### Recommendation

Stay with LSP-grounded edges via the existing `.lsp.json` setup until cross-language
accuracy gaps demonstrably hurt. Don't pre-install a graph DB. When/if you do, prefer
codegraph-rust unless the polyglot story really matters and the GitNexus license fits.

## 7. Verifying installation

After `hs`:

```bash
# Skill symlinked
ls -la ~/.claude/skills/refactor/SKILL.md

# Subagent symlinked
ls -la ~/.claude/agents/refactor-mapper.md

# CLAUDE.md migrated to nix store symlink
ls -la ~/.claude/CLAUDE.md

# Existing rules preserved
rg -F "fd instead of find" ~/.claude/CLAUDE.md

# New nudge present
rg -F "/refactor" ~/.claude/CLAUDE.md
```

Then in a fresh Claude Code session: type `/refac` and confirm `/refactor` autocompletes.
Invoke it against a small target in another repo and confirm the stop-and-wait fires
before any edit.

## 8. Honest limits

- **Advisory, not enforced.** Direct multi-file imperatives still bypass `/refactor`.
- **Proposal quality is not guaranteed.** The workflow makes propose→select easy; it
  doesn't make the underlying structural taste better. The leverage is the *stop*, not
  the proposals themselves.
- **Forgotten-invocation risk**. Two places where the user is likely to forget:
  - A "small fix" that creeps across files mid-edit. No natural pause point.
  - Direct multi-file imperatives ("update all X handlers to do Y") — autonomous
    matching may not fire even though the work is structurally a refactor.
- If forgetting becomes the bottleneck, the next step would be a soft warn-and-confirm
  `UserPromptSubmit` hook: pre-check the prompt for multi-file-structural markers and
  suggest `/refactor` before proceeding. Out of scope for the current advisory design.
