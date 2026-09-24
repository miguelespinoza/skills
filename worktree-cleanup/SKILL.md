---
name: worktree-cleanup
description: Reclaim disk by pruning merged or abandoned git worktrees (and, on macOS, stale iOS simulators and build caches), gated so nothing in use or holding uncommitted work is removed. Use for /worktree-cleanup, $worktree-cleanup, "what's using my disk", "clean up worktrees", "prune old worktrees", "free up space", or "delete old simulators".
---

# Worktree cleanup

You own the disk and the safety gate. Removing a worktree deletes files no code review will catch, so the gates below are the review.

## Steps

1. **Snapshot and audit.** Record `df -h /`. Run `scripts/worktree-audit.sh [repo]` from this skill's directory; it is read-only and the transcript search is slow, so run it in the background. It reads paths from `git worktree list`, never hand-typed ones, so agent-made worktrees (`.claude/worktrees/`, Haki, Codex, scratch dirs under `/tmp`) are included. For Haki's Codex sessions set `CHAT_DIRS=$HOME/.haki/codex-home/sessions`. Columns:
   - `MERGED`: which base branch (`BASE_BRANCHES`, default whichever of `origin/main|master|staging|develop` exist) already contains HEAD, or `no`. Squash merges show `no`, so read `PR` too.
   - `DIRTY`: `clean`, `wip:N` (tracked edits), or `scratch:N` (untracked files only).
   - `REMOTE`: `pushed`, `aheadN`, `no-remote`, `detached`, or `detached+N` (N commits no branch, remote, or tag reaches).
   - `PR`: your newest PR for the branch, `#123/MERGED|CLOSED|OPEN`.
   - `PROCS`: running processes whose working directory is inside the worktree (dev servers, agent sessions, shells).
   - `LAST_CHAT`: newest Claude Code or Codex transcript that worked in it: cwd, file paths, Codex workdir, `cd` or `git -C`.
2. **Read the buckets as advice, not permission.** In priority order:
   - `hold-in-use` (a live process), `hold-wip` (uncommitted tracked edits), `hold-stranded` (detached commits that would be lost), `hold-open-pr`: keep.
   - `verify-recent-chat`: a chat worked in it within `RECENT_DAYS` (default 4). Check before touching.
   - `safe`: merged into a base branch or its PR merged, clean, no live process.
   - `review`: no merge evidence, e.g. a closed-unmerged PR or a local-only branch. The user decides.
   - `prunable`: the directory is already gone; only `git worktree prune` is needed.
3. **Verify usage before deleting.** For each `verify-recent-chat` row, or anything you doubt, read the matching transcripts (fan out to subagents if your agent has them; transcripts are bulky) and report whether that chat is still ongoing or paused mid-task. Agents create sibling worktrees from background subagents, so a worktree can be in use without its name appearing anywhere the user looks.
4. **Present the prune set and get one confirmation.** Show the audit table, the set you propose to remove, and a one-line reason for everything held back. For `wip:N`, show the diff and get a decision per worktree: a clean worktree is recoverable from its branch, uncommitted work is gone. For `scratch:N`, name the files. Never remove `hold-*` rows without an explicit per-row yes.
5. **Prune the confirmed set.** Per path: `git worktree remove --force <path>`. If the directory survives on ignored build output, `rm -rf <path>`. Then `git worktree prune`. Never delete branches here: branch refs survive, so no committed work is lost and nothing deployed from a branch is affected. Confirm with `df -h /` and `git worktree list`.
6. **Other reclaimers, only if asked for more space.** Ask before each class; clear only caches the user hasn't said to keep.
   - iOS simulators (macOS with Xcode): `xcrun simctl --set testing delete all` (XCTest clones), `xcrun simctl delete unavailable`, and `xcrun simctl runtime list` then `xcrun simctl runtime delete <id>` for old runtimes.
   - Xcode `~/Library/Developer/Xcode/DerivedData` and `iOS DeviceSupport`.
   - Package caches: yarn, pnpm, npm, bun, brew, uv.

## Reply

`df -h /` before and after with the space reclaimed, the worktrees removed, and a one-line reason for each one held back (in use by which process or chat, uncommitted work, open PR, or awaiting a decision).

---

Adapted from the worktree-cleanup playbook in [pstack](https://github.com/cursor/plugins/tree/12d587d/pstack) by Lauren Tan ([@poteto](https://x.com/poteto)). MIT, see [LICENSE](LICENSE).
