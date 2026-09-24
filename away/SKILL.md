---
name: away
description: Run an OpenSpec change autonomously while the user is away. Vertical-slice implementation with e2e verification per slice, logged decisions instead of questions, and return notes. Use when the user will be unavailable and wants maximum progress without intervention.
---

# away — autonomous OpenSpec apply

Implement the OpenSpec change named in the user's request autonomously. In
Claude Code, `$ARGUMENTS` contains the text passed after `/away`; in Codex, use
the text supplied alongside the `$away` skill mention. If no change is named,
run `openspec list --json` and pick the change the user most recently worked on
(check git log / tasks file recency); state your pick and proceed — do not ask.

Invoke the `openspec-apply-change` skill for the mechanics of reading the change
and its tasks, then apply the operating rules below, which override its
pause-and-ask defaults.

## Context

The user is away and cannot answer questions. The goal is maximum verified
progress, not maximum lines of code. Every decision you'd normally ask about,
you instead decide, log, and move on.

## Operating rules

**1. Vertical slices, always verified.** Work in the thinnest slices that leave
the project in a dependable state. After each slice (one task or a small coherent
task group):
- It must build and pass the project's unit tests.
- If the project has an e2e/integration test framework, each slice must pass
  the existing e2e suite, and slices that add user-visible behavior must extend
  it. A slice is not done until its e2e path is green — even if the overall
  feature is incomplete. Partial feature + green e2e is the target state;
  complete feature + red e2e is failure.
- Commit the slice (follow the project's branch/commit conventions in
  CLAUDE.md; default: commit to the current branch, one commit per slice, task
  id in the message).
- If a slice goes red and you can't fix it in a reasonable number of attempts,
  `git revert`/reset the slice, log it in BLOCKED.md, and continue with the
  next slice. Never stack a new slice on top of a broken one — one broken slice
  is diagnosable; ten stacked are not.

**2. Circuit-breaker: search the web instead of spinning.** If you've failed to
fix the same problem 3 times with different approaches, stop guessing — the
assumption you're reasoning from is probably wrong or stale. Do a web search:
official docs, GitHub issues for the exact error string, release notes /
changelogs for version behavior, API references. Then retry with what you
learned. Also search *proactively* when the task involves a library/API whose
behavior you might be misremembering (check the version the project pins, not
the version you remember). Record the finding (and URL) in DECISIONS.md so the
user can audit it later. What you must NOT do: retry a 4th blind variation,
or scrape random forums when primary sources exist.

**3. Environment overrides.** If project docs (e.g. CLAUDE.md) forbid running
builds because "the developer runs a watcher," first check whether a watcher is
actually running (`ps aux | grep -i watch`, make targets, etc.). If none is
running, that rule is suspended — you may and should build and test. If one is
running, respect the rule and verify only by means that don't conflict.

**4. Decision policy — never stop to wait.**
- Ambiguous requirement → pick the most conservative option consistent with the
  spec and existing code, implement it, and append an entry to DECISIONS.md next
  to the change's tasks file: the choice, why, and the alternatives rejected.
- Genuinely blocked (missing credentials, destructive/irreversible ops, product
  judgment calls, actions project docs forbid) → skip the task, append it to
  BLOCKED.md with exactly what you need from the user, and continue. Never idle.
- Opportunistic refactors outside the change's scope → note in DECISIONS.md,
  do not implement.

**5. Project conventions are law.** Read CLAUDE.md (or equivalent) before
starting. Never hand-edit generated files, follow naming conventions, route
changes through the project's designated seams.

**6. Honest bookkeeping.** Update the tasks file checkboxes to reflect verified
reality only — never mark done what isn't built and tested. `openspec status`
must be truthful when the user returns.

## Before stopping

1. Run the project's full test command (and e2e suite if present) one final
   time; fix what you broke.
2. Write RETURN-NOTES.md next to the tasks file:
   - Slices completed (with commit hashes)
   - Decisions made (summary + pointer to DECISIONS.md)
   - Blocked items (pointer to BLOCKED.md) and what each needs
   - Current state: does it build? do tests pass? e2e green?
   - The exact first command the user should run to pick up where you left off
3. Leave the working tree clean — everything committed or deliberately stashed
   with a note.
