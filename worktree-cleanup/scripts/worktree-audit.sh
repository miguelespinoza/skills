#!/usr/bin/env bash
# Read-only worktree prune audit. Classifies every git worktree by size, merge
# state, uncommitted work, stranded commits, PR state, live processes, and the
# most recent Claude Code or Codex chat that ran inside it. Emits a table sorted by
# size with a suggested bucket. Never deletes anything.
# Adapted from pstack by Lauren Tan (MIT, see ../LICENSE).
#
# Usage: worktree-audit.sh [repo-path]   (defaults to the current repo)
#
# Env:
#   BASE_BRANCHES  space-separated refs a merged branch lands in.
#                  Default: whichever of origin/main, origin/master,
#                  origin/staging, origin/develop exist.
#   CHAT_DIRS      colon-separated extra transcript dirs to search.
#   RECENT_DAYS    chat activity window for verify-recent-chat (default 4).
set -u

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1

recent_days="${RECENT_DAYS:-4}"
now=$(date +%s)

mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
ymd() { date -r "$1" '+%Y-%m-%d' 2>/dev/null || date -d "@$1" '+%Y-%m-%d'; }

main_wt=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')

if [ -n "${BASE_BRANCHES:-}" ]; then
	bases="$BASE_BRANCHES"
else
	bases=""
	for b in main master staging develop; do
		git show-ref --verify --quiet "refs/remotes/origin/$b" && bases="$bases origin/$b"
	done
fi
for b in $bases; do
	git fetch origin "${b#origin/}" --quiet 2>/dev/null || echo "warn: could not fetch $b; merged column may be stale" >&2
done

prs=$(mktemp); chats=$(mktemp); cwds=$(mktemp)
trap 'rm -f "$prs" "$chats" "$cwds"' EXIT

# branch<TAB>#number/STATE, newest PR first.
gh pr list --author "@me" --state all --limit 1000 --json number,state,headRefName \
	--jq '.[] | "\(.headRefName)\t#\(.number)/\(.state)"' >"$prs" 2>/dev/null || : >"$prs"

# Transcripts touched in the last 30 days, from Claude Code and Codex.
chat_dirs="$HOME/.claude/projects:${CODEX_HOME:-$HOME/.codex}/sessions:$HOME/.codex/sessions:${CHAT_DIRS:-}"
IFS=: read -ra dirs <<<"$chat_dirs"
for d in "${dirs[@]}"; do
	[ -n "$d" ] && [ -d "$d" ] && find "$d" -name '*.jsonl' -mtime -30 2>/dev/null
done | sort -u >"$chats"
# Count a chat only where it worked in the worktree: its cwd, a file path it
# opened or patched, a Codex workdir, or a `cd`/`git -C` into it. A bare
# mention does not count, since `git worktree list` output names every tree.
search() {
	local re
	re=$(printf '%s' "$1" | sed 's/[][\.*^$+?(){}|]/\\&/g')
	re='("cwd":"(file://)?|"(file_path|notebook_path|path|workdir)":"|workdir(\\")?:\\"|File: |-C |cd )'"$re"'(/|"|[[:space:]]|\\|$)'
	if command -v rg >/dev/null; then xargs rg -l -e "$re" 2>/dev/null
	else xargs grep -l -E -e "$re" 2>/dev/null; fi
}

# Working directories of every running process we can see.
lsof -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' >"$cwds"

printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tPROCS\tLAST_CHAT\tBUCKET\tWORKTREE\n"

git worktree list --porcelain | awk '/^worktree /{print $2}' | while read -r wt; do
	[ "$wt" = "$main_wt" ] && continue
	if [ ! -d "$wt" ]; then
		printf -- "-\t-\t-\t-\t-\t-\t0\t-\tprunable\t%s\n" "$wt"
		continue
	fi

	size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
	head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
	head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
	age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

	# Squash merges are not ancestors of the base, so PR state is the stronger signal.
	merged=no
	for b in $bases; do
		git merge-base --is-ancestor "$head" "$b" 2>/dev/null && { merged="${b#origin/}"; break; }
	done

	porcelain=$(git -C "$wt" status --porcelain 2>/dev/null)
	if [ -z "$porcelain" ]; then dirty=clean
	elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
		dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
	else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

	branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
	# Commits no branch, remote, or tag reaches are lost when a detached worktree goes.
	stranded=0
	if [ -z "$branch" ]; then
		stranded=$(git rev-list --count "$head" --not --branches --remotes --tags 2>/dev/null || echo 0)
		remote=$([ "$stranded" -gt 0 ] && echo "detached+$stranded" || echo detached)
	elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
		[ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
			&& remote=pushed \
			|| remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
	else remote=no-remote; fi

	pr="-"
	[ -n "$branch" ] && pr=$(awk -F'\t' -v b="$branch" '$1==b {print $2; exit}' "$prs")
	[ -z "$pr" ] && pr="-"

	procs=$(awk -v w="$wt" '$0==w || index($0, w"/")==1' "$cwds" | wc -l | tr -d ' ')

	last="-"; last_ts=0
	f=$(search "$wt" <"$chats" | while read -r t; do echo "$(mtime "$t") $t"; done | sort -rn | head -1)
	if [ -n "$f" ]; then last_ts=${f%% *}; last=$(ymd "$last_ts"); fi
	recent=no
	[ "$last_ts" -gt 0 ] && [ $(( (now - last_ts) / 86400 )) -lt "$recent_days" ] && recent=yes

	if [ "$procs" -gt 0 ]; then bucket=hold-in-use
	elif [ "${dirty%%:*}" = wip ]; then bucket=hold-wip
	elif [ "$stranded" -gt 0 ]; then bucket=hold-stranded
	else case "$pr" in
		*OPEN) bucket=hold-open-pr ;;
		*) if [ "$recent" = yes ]; then bucket=verify-recent-chat
			elif [ "$merged" != no ] || [ "${pr##*/}" = MERGED ]; then bucket=safe
			else bucket=review; fi ;;
	esac; fi

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$procs" "$last" "$bucket" "$wt"
done | sort -t$'\t' -k1,1 -rh
