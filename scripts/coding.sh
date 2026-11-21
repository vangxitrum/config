#!/usr/bin/env bash
# Open the coding container (compose.coding.yaml) from anywhere.
#
# There is one long-lived container: it runs sshd on $CODING_SSH_PUBLISH, so
# `ssh -p 2222` and `coding` land in the same place. `coding` starts it if it
# is not running, then attaches.
#
#   coding              attach to its tmux session "coding" (created if missing)
#   coding zsh          run any other command in it instead
#
# Outbound access (the container reaches only what the egress proxy allows,
# see config/coding/egress-allow.txt). Run these on the host: the container
# can't approve its own access.
#   coding allow <entry>... [30m|2h|1d]   allow for a while (default 1h)
#   coding allow --permanent <entry>...   add to config/coding/egress-allow.txt
#   coding allow ls                       list temporary entries left
#   coding deny <entry>...                drop temporary and permanent entries
#   coding blocked [n]                    the n (20) most recent denied targets
#   coding audit                          repos whose git config/hooks could run code
#   entry: example.com  .example.com  example.com:5601  1.2.3.4[/24][:22]  host:5432
#
# Settings below apply when the container is CREATED. A running container is
# never recreated (that would kill SSH and tmux sessions). To change them, e.g.
# mount another project:  docker compose -f ~/work/config/compose.coding.yaml down
#
# Link it once: ln -sfn ~/work/config/scripts/coding.sh ~/.local/bin/coding
# Edit the settings below; anything already set in your environment wins.
set -euo pipefail

# ── settings ──────────────────────────────────────────────────────────────────
# Code mounted writable at the same path: all your repos by default. This repo
# and the vault's .obsidian/.git/memory are read-only on top of it; host git in
# it goes through scripts/git-guard.sh (see `coding audit`).
: "${CODING_WORKSPACE:=$HOME/work}"
# Host ~/.ssh mounted read-only at /home/coder/.ssh.
: "${CODING_SSH_DIR:=$HOME/.ssh}"
# Credential files for agents, mounted read-only at /run/secrets ($AGENT_SECRETS).
# Not under ~/.config: install.sh links config/* there, i.e. into this repo.
: "${CODING_SECRETS_DIR:=$HOME/.local/share/coding-secrets}"
# sshd inside the container: 1 on, 0 off. Host port and allowed client IPs
# (space/comma separated, CIDRs work).
: "${CODING_SSHD:=1}"
: "${CODING_SSH_PUBLISH:=2222}"
: "${CODING_SSH_ALLOW:=10.0.0.40}"
# Claude state: the `claude` named volume, or "$HOME/.claude" to share the host's.
# Sharing it lets the container write your host Claude settings, hooks
# included, which then run on the host: keep the volume unless you need it.
: "${CODING_CLAUDE_STATE:=claude}"
# ──────────────────────────────────────────────────────────────────────────────

install -d -m 0700 "$CODING_SECRETS_DIR"

CODING_WORKSPACE="$(readlink -f "$CODING_WORKSPACE")"
export CODING_WORKSPACE CODING_SSH_DIR CODING_SECRETS_DIR CODING_SSHD \
  CODING_SSH_PUBLISH CODING_SSH_ALLOW CODING_CLAUDE_STATE

# Resolve the repo through the ~/.local/bin symlink.
repo="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
compose=(docker compose --project-directory "$repo" -f "$repo/compose.coding.yaml")
export CODING_CONFIG_REPO="$repo"

# ── outbound allowlist ────────────────────────────────────────────────────────
allow_file="$repo/config/coding/egress-allow.txt"
temp_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/coding-egress"
temp_file="$temp_dir/temp"
install -d -m 0700 "$temp_dir"
[[ -e "$temp_file" ]] || : >"$temp_file"

valid_entry() { [[ "$1" =~ ^(host|[A-Za-z0-9.-]+|[0-9.]+/[0-9]+)(:[0-9]+)?$ ]]; }

egress_allow() {
	if [[ "${1:-}" == ls ]]; then
		local now
		now=$(date +%s)
		awk -v now="$now" '$1 > now { m = int(($1 - now) / 60); printf "%-40s %dh%02dm left\n", $2, m / 60, m % 60 }' "$temp_file"
		return
	fi
	local permanent=false secs=3600 entries=() e
	[[ "${1:-}" == --permanent ]] && { permanent=true; shift; }
	for e in "$@"; do
		if [[ "$e" =~ ^([0-9]+)([smhd])$ ]] && ! $permanent; then
			case "${BASH_REMATCH[2]}" in
			s) secs=${BASH_REMATCH[1]} ;; m) secs=$((BASH_REMATCH[1] * 60)) ;;
			h) secs=$((BASH_REMATCH[1] * 3600)) ;; d) secs=$((BASH_REMATCH[1] * 86400)) ;;
			esac
		elif valid_entry "$e"; then
			entries+=("$e")
		else
			echo "coding: not an entry: $e (see coding allow --help)" >&2
			exit 1
		fi
	done
	[[ ${#entries[@]} -gt 0 ]] || { sed -n '/^# Outbound access/,/^#   entry:/p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
	for e in "${entries[@]}"; do
		if $permanent; then
			grep -qxF "$e" "$allow_file" || printf '%s\n' "$e" >>"$allow_file"
			echo "coding: $e allowed permanently ($allow_file)"
		else
			printf '%s %s\n' "$(($(date +%s) + secs))" "$e" >>"$temp_file"
			echo "coding: $e allowed for $((secs / 60))m"
		fi
	done
	echo "coding: applies within ~10s"
}

egress_deny() {
	local e tmp
	for e in "$@"; do
		tmp=$(mktemp)
		awk -v e="$e" '$2 != e' "$temp_file" >"$tmp" && cat "$tmp" >"$temp_file"
		grep -vxF "$e" "$allow_file" >"$tmp" && cat "$tmp" >"$allow_file"
		rm -f "$tmp"
		echo "coding: $e denied"
	done
}

egress_blocked() {
	"${compose[@]}" exec -T egress sh -c \
		"awk '\$2 ~ /DENIED/ { print \$4 }' /var/log/squid/access.log 2>/dev/null" |
		sed -E 's#^[a-z]+://##; s#/.*##' | awk '{ n[$0]++; last[$0] = NR } END { for (h in n) print last[h], n[h], h }' |
		sort -n | tail -n "${1:-20}" | awk '{ printf "%-50s %d denied\n", $3, $2 }'
	echo "coding: allow one with: coding allow <host[:port]> [30m|2h|1d]  (or --permanent)" >&2
}

case "${1:-}" in
allow) shift; egress_allow "$@"; exit ;;
deny) shift; egress_deny "$@"; exit ;;
blocked) shift; egress_blocked "$@"; exit ;;
audit) shift; exec "$repo/scripts/git-guard.sh" audit "${1:-$CODING_WORKSPACE}" ;;
esac

# The workspace is writable from the container: never your home (keys, shell
# rc, every dotfile) or /. Only checked when creating the container.
creating=false
[[ -z "$("${compose[@]}" ps -aq coding 2>/dev/null)" ]] && creating=true
if $creating; then
	home="$(readlink -f "$HOME")"
	if [[ "$CODING_WORKSPACE" == / || "$home/" == "$CODING_WORKSPACE/"* ]]; then
		echo "coding: won't mount $CODING_WORKSPACE writable: it is or contains your home." >&2
		echo "coding: set CODING_WORKSPACE to your code folder (default ~/work)." >&2
		exit 1
	fi
	# Report repos whose git config/hooks could run code (git-guard blocks them).
	"$repo/scripts/git-guard.sh" audit "$CODING_WORKSPACE" || true
fi

# Start it if needed; --no-recreate leaves a running one alone.
"${compose[@]}" up -d --no-recreate coding

[[ $# -eq 0 ]] && set -- tmux new-session -A -s coding
# Start in the directory you ran `coding` from when the container can see it.
workdir=()
[[ "$(pwd -P)/" == "$CODING_WORKSPACE/"* ]] && workdir=(-w "$(pwd -P)")
exec "${compose[@]}" exec "${workdir[@]}" coding "$@"
