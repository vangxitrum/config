#!/bin/sh
# git-guard.sh - host-side guard for git in repos the coding container can write.
#
# The coding container (compose.coding.yaml) can write every repo under
# ~/work, including .git/config and .git/hooks. Many git settings make git run
# a program (core.fsmonitor, core.pager, core.sshCommand, hooks, diff/filter
# drivers, ...), so a tampered repo would run code on the host the next time
# the host's git, lazygit or nvim's gitsigns touches it. Linked as
# ~/.local/bin/git, this checks the repo first and refuses until you approve
# what it found. Inside the coding container (IS_SANDBOX=1) and outside
# $GIT_GUARD_ROOT it just runs git.
#
# Link once, on the host only:
#   ln -sfn ~/work/config/scripts/git-guard.sh ~/.local/bin/git
#   ln -sfn ~/work/config/scripts/git-guard.sh ~/.local/bin/git-guard
#
# Usage: git ...                     (as the shim)
#        git-guard audit [dir]       list repos under dir (~/work) with unapproved findings
#        git-guard approve <repo>    show the findings, approve them after checking
#        GIT_GUARD_OFF=1 git ...     skip the check once
#
# An approval covers exactly what was found (values and hook contents): any
# later change is flagged again.

REAL_GIT="${GIT_GUARD_REAL:-/usr/bin/git}"
ROOT="${GIT_GUARD_ROOT:-$HOME/work}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/git-guard/approved"

# Config keys (git config --list form, lowercased) that run a program or
# change where git connects.
RISKY='^(core\.(fsmonitor|hookspath|pager|sshcommand|editor|askpass|gitproxy)|sequence\.editor|pager\..*|diff\.external|diff\..*\.(textconv|command)|filter\..*\.(clean|smudge|process)|merge\..*\.driver|credential\..*|gpg\.(.*\.)?program|include\.path|includeif\..*|remote\..*\.(uploadpack|receivepack|vcs)|url\..*\.(insteadof|pushinsteadof)|protocol\..*\.allow|submodule\..*\.update|interactive\.difffilter|alias\..*)$'

# Repo top-level and git dir for a directory: prints "<gitdir>", or fails.
find_gitdir() {
	d=$(cd "$1" 2>/dev/null && pwd -P) || return 1
	while :; do
		if [ -d "$d/.git" ]; then
			printf '%s\n' "$d/.git"
			return 0
		elif [ -f "$d/.git" ]; then
			g=$(sed -n 's/^gitdir: //p' "$d/.git")
			case "$g" in /*) ;; *) g="$d/$g" ;; esac
			(cd "$g" 2>/dev/null && pwd -P)
			return
		fi
		[ "$d" = / ] && return 1
		d=$(dirname "$d")
	done
}

# Findings for a git dir, one per line ("config: k=v", "hook: name sum").
scan() {
	for g in "$1" $( [ -f "$1/commondir" ] && (cd "$1" && cd "$(cat commondir)" && pwd -P) ); do
		[ -f "$g/config" ] &&
			(cd / && env -u GIT_DIR -u GIT_CONFIG "$REAL_GIT" config --file "$g/config" --list 2>/dev/null) |
			awk -v re="$RISKY" '{ k = tolower(substr($0, 1, index($0, "=") - 1)); if (k ~ re) print "config: " $0 }'
		# Hooks in .git/hooks, or in core.hooksPath (often a tracked .githooks/,
		# relative to the work tree), with their contents' checksums.
		hp=$( [ -f "$g/config" ] && (cd / && "$REAL_GIT" config --file "$g/config" core.hooksPath 2>/dev/null) )
		case "$hp" in "") hp="$g/hooks" ;; /*) ;; *) hp="$(dirname "$g")/$hp" ;; esac
		[ -d "$hp" ] && find "$hp" -maxdepth 1 -type f ! -name '*.sample' 2>/dev/null | sort |
			while IFS= read -r h; do printf 'hook: %s %s\n' "${h##*/}" "$(cksum <"$h" | cut -d' ' -f1)"; done
	done
}

approved() { # gitdir findings
	sum=$(printf '%s\n' "$2" | cksum | cut -d' ' -f1)
	grep -qxF "$1 $sum" "$STATE" 2>/dev/null
}

under_root() {
	r=$(cd "$ROOT" 2>/dev/null && pwd -P) || return 1
	case "$1/" in "$r"/*) return 0 ;; esac
	return 1
}

shim() {
	{ [ "${IS_SANDBOX:-}" = 1 ] || [ -n "${GIT_GUARD_OFF:-}" ]; } && exec "$REAL_GIT" "$@"
	# Directory git will work in: the last -C before the subcommand, else $PWD.
	dir=$PWD
	gitdir=${GIT_DIR:-}
	n=$#
	i=1
	while [ $i -le $n ]; do
		eval "a=\${$i}"
		case "$a" in
		-C) i=$((i + 1)); eval "c=\${$i}"; case "$c" in /*) dir=$c ;; *) dir="$dir/$c" ;; esac ;;
		--git-dir=*) gitdir=${a#--git-dir=} ;;
		-c | --exec-path | --namespace | --work-tree | --git-dir | --config-env) i=$((i + 1)) ;;
		-*) ;;
		*) break ;;
		esac
		i=$((i + 1))
	done
	if [ -n "$gitdir" ]; then
		case "$gitdir" in /*) ;; *) gitdir="$dir/$gitdir" ;; esac
		gd=$(cd "$gitdir" 2>/dev/null && pwd -P) || exec "$REAL_GIT" "$@"
	else
		gd=$(find_gitdir "$dir") || exec "$REAL_GIT" "$@"
	fi
	under_root "$gd" || exec "$REAL_GIT" "$@"
	found=$(scan "$gd")
	[ -z "$found" ] && exec "$REAL_GIT" "$@"
	approved "$gd" "$found" && exec "$REAL_GIT" "$@"
	repo=${gd%/.git}
	{
		echo "git-guard: not running git in $repo: its git config or hooks can run programs,"
		echo "git-guard: and the coding container can write this repo:"
		printf '%s\n' "$found" | sed 's/^/    /'
		echo "git-guard: if you set these up yourself: git-guard approve $repo"
		echo "git-guard: otherwise remove them (and check what changed them) before using git here."
	} >&2
	exit 128
}

audit() {
	root=$(cd "${1:-$ROOT}" && pwd -P) || exit 1
	bad=0
	for gd in $(find "$root" -maxdepth 5 -name .git \( -type d -o -type f \) -not -path '*/node_modules/*' 2>/dev/null); do
		[ -f "$gd" ] && gd=$(find_gitdir "${gd%/.git}")
		found=$(scan "$gd")
		[ -n "$found" ] || continue
		approved "$gd" "$found" && continue
		bad=1
		echo "${gd%/.git}:"
		printf '%s\n' "$found" | sed 's/^/    /'
	done
	[ $bad = 0 ] || echo "git-guard: check these, then: git-guard approve <repo>" >&2
	return $bad
}

approve() {
	[ -n "${1:-}" ] || { echo "usage: git-guard approve <repo>" >&2; exit 2; }
	gd=$(find_gitdir "$1") || { echo "git-guard: not a git repo: $1" >&2; exit 1; }
	found=$(scan "$gd")
	[ -n "$found" ] || { echo "git-guard: nothing to approve in ${gd%/.git}"; exit 0; }
	echo "In ${gd%/.git}:"
	printf '%s\n' "$found" | sed 's/^/    /'
	printf 'Approve exactly these (y/N)? '
	read -r ans </dev/tty
	case "$ans" in y | Y | yes) ;; *) echo "not approved"; exit 1 ;; esac
	mkdir -p "$(dirname "$STATE")"
	printf '%s %s\n' "$gd" "$(printf '%s\n' "$found" | cksum | cut -d' ' -f1)" >>"$STATE"
	echo "approved"
}

case "${0##*/}" in
git) shim "$@" ;;
esac
case "${1:-}" in
audit) shift; audit "$@" ;;
approve) shift; approve "$@" ;;
*) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
