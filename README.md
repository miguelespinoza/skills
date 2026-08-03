# skills

My personal [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Each top-level folder is one skill, defined by a `SKILL.md`.

## Skills

| Skill | What it does |
| --- | --- |
| [`away`](./away) | Autonomous OpenSpec apply while you're out: vertical slices, e2e-verified per slice, decisions logged instead of questions, return notes when you're back. Run `/away <change>`. |
| [`extract-pr`](./extract-pr) | Move this chat session's changes onto a fresh branch and open a PR — without committing to or switching the current branch. Figures out the session's files itself and extracts only its own hunks when parallel agents touched the same files. Run `/extract-pr` in Claude Code or `$extract-pr` in Codex. |
| [`wrapup`](./wrapup) | One-sentence session recap plus a counted list of open loops (unfinished, unverified, or deferred work). Run `/wrapup`. |

## Install

Clone anywhere, then symlink each skill into `~/.claude/skills/`:

```bash
git clone git@github.com:miguelespinoza/skills.git ~/code/skills
~/code/skills/install.sh
```

`install.sh` symlinks every folder containing a `SKILL.md` into `~/.claude/skills/`, so edits here are live immediately and `git push` syncs them.

## Adding a skill

1. Create `<name>/SKILL.md` with frontmatter (`name`, `description`) and instructions.
2. Run `./install.sh` to link it.
3. Commit and push.
