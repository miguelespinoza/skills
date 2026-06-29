#!/usr/bin/env bash
# Symlink every skill in this repo into ~/.claude/skills/. Idempotent.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

for dir in "$SRC"/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name="$(basename "$dir")"
  ln -sfn "$dir" "$DEST/$name"
  echo "linked $name -> $dir"
done
