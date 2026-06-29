# skills

My personal [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Each top-level folder is one skill, defined by a `SKILL.md`.

## Skills

| Skill | What it does |
| --- | --- |
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
