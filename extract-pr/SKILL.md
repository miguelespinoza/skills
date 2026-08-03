---
name: extract-pr
description: Extract the work done in this chat session into a PR on a fresh branch WITHOUT committing to or switching the current branch. Use on /extract-pr or asks like "PR this work", "get this into a PR but leave staging alone", "commit what we changed to a new branch", "move this session's work to a worktree and open a PR" — especially when the user is sitting on a shared branch (staging, main) with unrelated work in the tree. Determine the files yourself from the session's edits — never ask the user for a file list. When other agents or the user touched the same files in parallel, extract only the hunks belonging to this session's change. Not for ordinary commits on the current branch, and not for work made outside this session.
---

# Extract session work into a PR

Move exactly the changes made in this chat session onto a fresh branch and open a PR, leaving the current checkout on its branch with all unrelated work untouched. The vehicle is a patch file, not the stash: patches can be filtered to individual hunks, and a private patch file cannot race with other sessions the way the repo-wide shared stash stack can.

## 1. Identify what this session changed

Build the file list from the conversation, not from the user:

- Every file you created or modified with Edit/Write in this session, minus anything you later reverted (temp debug logs, scratch files) and anything outside the repo.
- Intersect with `git status --porcelain`. A session file that is clean was already committed — note it and skip it. A dirty file you never touched is someone else's work — leave it alone entirely.
- Do not ask the user which files to include. Only surface a question if a file's ownership is genuinely undecidable after the hunk audit below.

## 2. Audit for foreign hunks

Other agents or the user may have edited the same files in parallel. For each candidate file, run `git diff -- <file>` and match every hunk against the edits you actually made this session (you have them in context).

- All hunks yours → take the whole file.
- Mixed → take only your hunks (next step).
- A single hunk contains both your lines and foreign lines → regenerate with less context (`git diff -U1` or `-U0 -- <file>`) so the edits separate into distinct hunks. If the same lines were edited by both parties, stop and show the user that specific overlap — committing someone else's work under your PR is the one unrecoverable mistake here.

## 3. Build the patch

```bash
git diff -- <files> > "$SCRATCH/extract.patch"
```

If filtering is needed, write a filtered copy containing only your hunks: keep each file's `diff --git`/`---`/`+++` header block, keep your `@@` hunks verbatim, drop foreign hunks whole. Hunk headers carry absolute old-file line numbers, so removing sibling hunks does not invalidate the ones you keep. Validate with `git apply --check --stat` against a clean base before going further.

Keep the patch file until the PR exists — it is the recovery artifact if anything downstream fails.

## 4. Worktree, branch, apply

- Base and PR target = the branch the user is currently on, unless they said otherwise.
- Derive a branch name from the change (`fix/...`, `feat/...`); check it is free with `git rev-parse --verify`.

```bash
git worktree add ../<repo>-wt-<slug> -b <branch> <base>
cd ../<repo>-wt-<slug>
git apply --check extract.patch && git apply extract.patch
```

If `--check` fails, the base drifted from what the diff was taken against — stop and report; never force or fuzz the apply.

## 5. Commit, push, PR

Commit in the worktree, `git push -u origin <branch>`, then `gh pr create --base <base>` with a body that says what changed and how it was verified.

Fresh worktrees have no `node_modules`, so hook runners like husky fail on commit. Run the cheap verification (typecheck/lint of the touched files) in the main checkout first, then commit with `--no-verify` — do not install dependencies into a throwaway worktree just to satisfy a hook you already satisfied elsewhere.

## 6. Remove the extracted changes from the source tree

The work moved, so take it out of the original checkout — but surgically:

```bash
cd <main-checkout>
git apply -R "$SCRATCH/extract.patch"
```

Reverse-applying the exact patch removes only the extracted hunks. Never `git checkout --` or `git restore` a file that had foreign hunks — that wipes the other party's work. Afterwards run `git diff` on the touched files and confirm the foreign hunks are still present.

## 7. Clean up and report

- `git worktree remove ../<repo>-wt-<slug>` (only after the push succeeded).
- Leave the patch in the scratchpad and tell the user its path.
- Report: PR URL, files extracted (whole vs. hunk-filtered), any foreign work deliberately left behind, and that the current branch/checkout is untouched.

## Guardrails

- Stale `.git/index.lock`: if git errors with "could not write index", check the lock. Zero bytes and no running git process → delete it and retry once. Otherwise stop and report — another process may genuinely hold it.
- Never push a stash as part of this flow. If you must fall back to one, pin its SHA immediately (`git rev-parse 'stash@{0}'`) and apply/drop by SHA only — `stash@{0}` is a moving target when parallel sessions share the repo.
- If there are no session changes to extract (everything clean or already committed), say so and stop; do not invent a diff.
