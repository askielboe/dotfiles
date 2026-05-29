---
name: refactor
description: Use for structural or multi-file refactors. Maps blast radius via the refactor-mapper subagent, presents 2–3 DISTINCT proposals, then STOPS for user selection before any edits. Do NOT use for single-file bug fixes or in-place tweaks — only when the change crosses module/file boundaries or alters architecture.
---

# /refactor — disciplined refactoring workflow

You are running the `/refactor` skill. The contract below is mandatory. The single
load-bearing rule is **step 5: STOP and wait for the user's selection before any edits.**

## Step 1 — Confirm scope

Restate the target subsystem in one sentence, e.g. "Refactor target: the
`citadel-sync::ingest` module and its consumers in `citadel-app`."

If the target is ambiguous (no clear entry point, no named area, "clean up this code"),
ask the user for the entry-point file(s) or area name. **Do not proceed past this step
without an explicit target.** Guessing here defeats the workflow.

## Step 2 — Invoke the refactor-mapper subagent

Use the `refactor-mapper` subagent (it is read-only — Read, Grep, Glob only) with a prompt
containing:

- The target scope sentence from step 1.
- The language stack (e.g. "Rust" / "Swift" / "Rust + Swift").
- If the target spans Rust + Swift, explicitly request **two parallel passes** — one per
  language — that reconcile at the FFI/bridge boundary.
- Whether `.lsp.json` is wired (it usually is for this user — rust-analyzer and
  sourcekit-lsp). Tell the mapper to prefer LSP-grounded edges over text grep where
  available.

The mapper returns map text inline. **Do not start editing.**

## Step 3 — Write the map to disk

Take the mapper's returned text and write it to:

```
.claude/refactor-maps/<ISO-timestamp>-<short-slug>.md
```

…in the current project (mkdir -p the directory first; it likely doesn't exist yet).
Use the slug form of the target, e.g. `2026-05-30T14-30-00-citadel-sync-ingest.md`.

Reference the written path back to the user in one line:

> Map written to `.claude/refactor-maps/2026-05-30T14-30-00-citadel-sync-ingest.md`.

## Step 4 — Generate 2–3 DISTINCT proposals

Each proposal MUST be a **structurally different** approach — not three rewordings of one
idea. Genuine examples of distinct categories: extract-trait vs split-module vs
invert-dependency vs introduce-facade vs collapse-layers vs change-data-flow-direction.

If you cannot name three genuinely distinct options, present two. **Never pad to three
with a near-duplicate.**

For each proposal, output the following four fields in this exact order:

- **What changes** — 2–4 bullets describing the structural edit.
- **Blast radius** — files / call sites touched, integration surface affected, public-API
  shifts. Be specific (counts, paths).
- **Tradeoff** — what gets better, what gets worse. Both sides required.
- **What could break** — the specific failure mode you'd watch for (e.g. "trait coherence
  conflict on downstream `impl Foo for T`", "Swift `@objc` selector drift breaks the
  Obj-C bridge").

## Step 5 — STOP

Output the proposals, then this literal line on its own:

```
Awaiting your selection (1 / 2 / 3) before any edits.
```

**Do NOT default to option 1. Do NOT begin edits. Do NOT propose "I'll start with
option 2 unless you object."** Wait for the user's explicit reply.

If the user redirects ("none of these — what about X?"), loop back to step 4 with the
new constraint. Do not skip ahead to editing.

## Step 6 — On selection: implement narrowly

When the user picks an option:

1. Create a branch: `refactor/<short-slug>` (e.g. `refactor/citadel-sync-ingest-extract-trait`).
2. Implement the chosen proposal scope only. Do not bundle drive-by cleanups.
3. Run the repo's tests and linter (look for `just`, `cargo test`, `swift test`, etc.).
4. If the implementation drifts from the proposal (you discover the blast radius is
   bigger, or a step requires an unstated change), **pause and surface the drift to the
   user** before continuing. Do not silently expand scope.
5. Report what changed at the end, referencing the map file path.
