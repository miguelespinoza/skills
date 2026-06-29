---
name: wrapup
description: One-line session recap plus a counted list of open loops. Use on /wrapup or asks like "wrap up", "where did we land", "what's left to close".
---

Read the conversation only — do not re-run work or start anything new. Output exactly this shape:

1. **One sentence** recapping the session (what we did / where we landed). Same brevity as a `/recap`.
2. A line stating the count: **"N open loops:"** (or **"No open loops."** if zero).
3. If N > 0, a bullet list — one line per loop, what it is + next action.

Count and list anything not fully closed; only include items that genuinely apply:
- started but unfinished, or stubbed / mocked / `TODO` / `FIXME`
- skipped follow-on — callers not updated, tests not added
- unverified — tests not run, build not checked, behavior not confirmed
- uncommitted work when a commit was implied
- questions raised but never resolved
- anything we said we'd "do next" and didn't

No headers, no preamble, no filler.
