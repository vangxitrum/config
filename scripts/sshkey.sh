#!/usr/bin/env bash
# sshkey.sh - ssh-agent on demand, keys picked by hand, passphrases asked in
# the terminal (never a GUI dialog).
#
# The agent listens on a fixed socket, $XDG_RUNTIME_DIR/ssh-agent.sock, which
# home/.zshrc exports as SSH_AUTH_SOCK, so every terminal sees the keys once
# they are added. Nothing starts it at login; it lives until `sshkey stop`.
# GUI apps don't get SSH_AUTH_SOCK (they don't read .zshrc).
#
# Usage: sshkey [-t <life>] [pick|all|<key>...]   add keys (default: pick)
#        sshkey ls                                 list loaded keys
#        sshkey rm [<key>...]                      unload keys (pick if none)
#        sshkey stop                               kill the agent, forget all keys
#        sshkey setup                              one time: disable the session's
#                                                  automatic agents (gcr/GNOME keyring,
#                                                  gpg-agent ssh, systemd ssh-agent)
#   -t <life>  forget the added keys after this long (ssh-add -t: 30m, 4h, ...)
#   pick       fzf multi-select (Tab marks, Enter adds; pick "ALL" for every key)
#   all        every private key in ~/.ssh (except $SSHKEY_EXCLUDE)
#   <key>      a name in ~/.ssh (github) or a path
set -euo pipefail

SSH_DIR="$HOME/.ssh"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.sock"
# Not login keys: pgpass is the age identity for scripts/pgpass.sh.
SSHKEY_EXCLUDE="${SSHKEY_EXCLUDE:-pgpass}"
export SSH_AUTH_SOCK="$SOCK"
# Always ask in the terminal, even with DISPLAY set.
export SSH_ASKPASS_REQUIRE=never

die() { echo "sshkey: $*" >&2; exit 1; }

# ssh-add -l: 0 = keys, 1 = no keys, 2 = no agent.
agent_up() {
	local rc=0
	ssh-add -l >/dev/null 2>&1 || rc=$?
	[ "$rc" -ne 2 ]
}

ensure_agent() {
	agent_up && return
	rm -f "$SOCK" "$SOCK.pid"
	local out
	out="$(ssh-agent -a "$SOCK")" || die "could not start ssh-agent"
	sed -n 's/^SSH_AGENT_PID=\([0-9]*\);.*/\1/p' <<<"$out" >"$SOCK.pid"
	echo "sshkey: started agent on $SOCK"
}

# Private keys in ~/.ssh, by name.
list_keys() {
	local f name
	for f in "$SSH_DIR"/*; do
		[ -f "$f" ] || continue
		name="${f##*/}"
		case "$name" in *.pub | config* | known_hosts* | authorized_keys*) continue ;; esac
		[[ " $SSHKEY_EXCLUDE " == *" $name "* ]] && continue
		head -c 64 "$f" 2>/dev/null | grep -q 'PRIVATE KEY' || continue
		printf '%s\n' "$name"
	done
}

resolve() {
	if [ -f "$1" ]; then printf '%s\n' "$1"
	elif [ -f "$SSH_DIR/$1" ]; then printf '%s\n' "$SSH_DIR/$1"
	else die "no key '$1' in $SSH_DIR"
	fi
}

pick() { # pick <prompt> <lines...> -> chosen lines
	local prompt="$1"
	shift
	command -v fzf >/dev/null || die "fzf not installed; pass key names or 'all'"
	printf '%s\n' "$@" | fzf --multi --height=40% --reverse --prompt="$prompt> " \
		--header='Tab: mark  Enter: confirm' || true
}

cmd_add() {
	local life=() keys=() k
	if [ "${1:-}" = "-t" ]; then
		[ -n "${2:-}" ] || die "-t needs a lifetime (30m, 4h, ...)"
		life=(-t "$2")
		shift 2
	fi
	case "${1:-pick}" in
	pick)
		mapfile -t keys < <(pick "add key" ALL $(list_keys))
		[ "${#keys[@]}" -gt 0 ] || { echo "sshkey: nothing chosen"; return; }
		if printf '%s\n' "${keys[@]}" | grep -qx ALL; then
			mapfile -t keys < <(list_keys)
		fi
		;;
	all) mapfile -t keys < <(list_keys) ;;
	*) keys=("$@") ;;
	esac
	[ "${#keys[@]}" -gt 0 ] || die "no private keys found in $SSH_DIR"
	ensure_agent
	local paths=()
	for k in "${keys[@]}"; do paths+=("$(resolve "$k")"); done
	# One ssh-add call: keys sharing a passphrase are unlocked with one prompt.
	ssh-add "${life[@]}" "${paths[@]}"
}

cmd_ls() {
	agent_up || { echo "sshkey: no agent (run 'sshkey' to start one)"; return; }
	ssh-add -l || true
}

cmd_rm() {
	agent_up || die "no agent running"
	local keys=() k
	if [ "$#" -eq 0 ]; then
		# Loaded keys show by comment; match them back to files in ~/.ssh.
		mapfile -t keys < <(pick "remove key" ALL $(list_keys))
		[ "${#keys[@]}" -gt 0 ] || return
		if printf '%s\n' "${keys[@]}" | grep -qx ALL; then
			ssh-add -D
			return
		fi
	else
		keys=("$@")
	fi
	for k in "${keys[@]}"; do ssh-add -d "$(resolve "$k")" || true; done
}

cmd_stop() {
	agent_up && ssh-add -D >/dev/null 2>&1 || true
	if [ -s "$SOCK.pid" ]; then
		kill "$(cat "$SOCK.pid")" 2>/dev/null || true
	fi
	rm -f "$SOCK" "$SOCK.pid"
	echo "sshkey: agent stopped"
}

# User-level only (no sudo): mask the units that start an agent for the whole
# session and publish it through systemd's environment, where GUI apps and
# kitty pick it up. GNOME Keyring's password store (Slack, browsers) stays.
cmd_setup() {
	local units=(gcr-ssh-agent.socket gcr-ssh-agent.service
		gpg-agent-ssh.socket ssh-agent.socket ssh-agent.service)
	systemctl --user stop "${units[@]}" 2>/dev/null || true
	systemctl --user mask "${units[@]}" >/dev/null
	# D-Bus-activated apps: clear it there too (dbus-broker forwards this to
	# systemd as an empty value), then drop it from systemd's environment.
	if command -v dbus-update-activation-environment >/dev/null; then
		dbus-update-activation-environment SSH_AUTH_SOCK= 2>/dev/null || true
	fi
	systemctl --user unset-environment SSH_AUTH_SOCK
	echo "sshkey: masked ${units[*]}"
	echo "sshkey: new terminals use $SOCK; run 'sshkey' when you need keys."
}

case "${1:-pick}" in
ls | list) cmd_ls ;;
rm | remove) shift; cmd_rm "$@" ;;
stop | kill) cmd_stop ;;
setup) cmd_setup ;;
-h | --help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//' ;;
add) shift; cmd_add "$@" ;;
*) cmd_add "$@" ;;
esac
