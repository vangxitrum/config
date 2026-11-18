#!/bin/sh
# coding-entrypoint.sh - entrypoint of the coding image (Dockerfile.coding).
# Creates the runtime dir, starts the firewall + sshd (scripts/coding-sshd.sh)
# unless CODING_SSHD=0, then runs the command (tmux by default).
set -e

install -d -m 0700 "$XDG_RUNTIME_DIR"

if [ "${CODING_SSHD:-1}" = 1 ]; then
	# SSH sessions don't inherit this environment; coding-sshd.sh installs it
	# as /etc/environment (pam_env). Written here because sudo drops ZDOTDIR
	# and resets PATH. A failure doesn't stop the container.
	env | grep -E '^(PATH|EDITOR|LANG|ZDOTDIR|CLAUDE_CONFIG_DIR|CODEX_HOME|XDG_RUNTIME_DIR|AGENT_NOTIFY_SPOOL|IS_SANDBOX)=' \
		>"$XDG_RUNTIME_DIR/ssh-environment"
	sudo CODING_SSH_ALLOW="${CODING_SSH_ALLOW:-}" CODING_SSH_PORT="${CODING_SSH_PORT:-}" \
		/usr/local/sbin/coding-sshd "$XDG_RUNTIME_DIR/ssh-environment" || true
fi

exec "$@"
