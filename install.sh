#!/usr/bin/env bash
# Symlink every skill into Claude Code and OpenAI Codex's user skill directories.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
destinations=(
  "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
  "$HOME/.agents/skills"
)

for destination in "${destinations[@]}"; do
  mkdir -p "$destination"

  for skill_directory in "$repo"/*/; do
    [ -f "$skill_directory/SKILL.md" ] || continue

    skill_directory="${skill_directory%/}"
    name="$(basename "$skill_directory")"
    target="$destination/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "refusing to replace non-symlink: $target" >&2
      exit 1
    fi

    ln -sfn "$skill_directory" "$target"
    echo "linked $name -> $target"
  done
done
