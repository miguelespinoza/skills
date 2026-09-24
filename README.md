# skills

My personal skills for [Claude Code](https://code.claude.com/docs/en/slash-commands) and [OpenAI Codex](https://developers.openai.com/codex/). Each top-level folder is one skill, defined by a `SKILL.md`.

## Skills

| Skill | What it does |
| --- | --- |
| [`away`](./away) | Autonomous OpenSpec apply while you're out: vertical slices, e2e-verified per slice, decisions logged instead of questions, return notes when you're back. Run `/away <change>` in Claude Code or `$away <change>` in Codex. |
| [`extract-pr`](./extract-pr) | Move this chat session's changes onto a fresh branch and open a PR — without committing to or switching the current branch. Figures out the session's files itself and extracts only its own hunks when parallel agents touched the same files. Run `/extract-pr` in Claude Code or `$extract-pr` in Codex. |
| [`wrapup`](./wrapup) | One-sentence session recap plus a counted list of open loops (unfinished, unverified, or deferred work). Run `/wrapup` in Claude Code or `$wrapup` in Codex. |

## Install

Clone anywhere, then symlink each skill into Claude Code's `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/` and Codex's `~/.agents/skills/`:

```bash
git clone git@github.com:miguelespinoza/skills.git ~/code/skills
~/code/skills/install.sh
```

`install.sh` symlinks every folder containing a `SKILL.md` into both tools' user skill directories, so edits here are live immediately and `git push` syncs them. If you use multiple `CLAUDE_CONFIG_DIR` values, run the installer once with each value.

## Adding a skill

1. Create `<name>/SKILL.md` with frontmatter (`name`, `description`) and instructions.
2. Run `./install.sh` to link it.
3. Commit and push.
