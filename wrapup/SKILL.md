---
name: wrapup
description: One-line session recap plus a counted list of open loops. Use on /wrapup or asks like "wrap up", "where did we land", "what's left to close".
---

This is a **status snapshot, not a sign-off.** Producing it does not mean the session is ending, the work is done, or that anyone has decided to stop. Open loops are *live work*, not closed business. After you output the recap, hold your prior stance: the default next step is to keep working the open loops, not to wind down. Do not shift into a "we're finishing up" frame, and do not treat this recap as a decision to stop unless the user says so.

Read the conversation only — do not re-run work or start anything new. Output exactly this shape:

1. **One sentence** recapping current state (what we've done / where things stand right now). Same brevity as a `/recap`. Phrase it as a status check, not a conclusion — avoid sign-off language ("all wrapped up", "we're done here", "good place to stop").
2. A line stating the count: **"N open loops:"** (or **"No open loops."** if zero).
3. If N > 0, a numbered list (1., 2., 3., …) — one line per loop, what it is + next action.

Count and list anything not fully closed; only include items that genuinely apply:
- started but unfinished, or stubbed / mocked / `TODO` / `FIXME`
- skipped follow-on — callers not updated, tests not added
- unverified — tests not run, build not checked, behavior not confirmed
- uncommitted work when a commit was implied
- questions raised but never resolved
- anything we said we'd "do next" and didn't

No headers, no preamble, no filler.
