#!/bin/sh
# coding-sshd.sh - start the coding container's firewall and sshd (as root).
#
# Called by scripts/coding-entrypoint.sh through sudo, with the path of the
# environment file for SSH sessions as $1. Fails closed: if
# ufw can't be enabled (no NET_ADMIN), sshd is not started.
#
# Env (compose.coding.yaml):
#   CODING_SSH_ALLOW  addresses/CIDRs allowed to reach sshd, space or comma
#                     separated (required; nothing else gets in)
#   CODING_SSH_PORT   sshd port inside the container (default 2222)
#
# The real client IP is only visible with rootless Docker's slirp4netns port
# driver (scripts/docker.sh); with the builtin driver every client would be
# 172.17.0.1 and ufw would let nobody in.
set -eu

port="${CODING_SSH_PORT:-2222}"
allow="$(printf '%s' "${CODING_SSH_ALLOW:-}" | tr ',' ' ')"
log=/var/log/coding-sshd.log
keys=/etc/ssh/host_keys

[ -n "$allow" ] || { echo "coding-sshd: CODING_SSH_ALLOW is empty, not starting sshd" >&2; exit 1; }

# Host key in a volume, so it survives rebuilds (no known_hosts warnings).
mkdir -p "$keys"
[ -f "$keys/ssh_host_ed25519_key" ] ||
	ssh-keygen -q -t ed25519 -N "" -C "config-coding" -f "$keys/ssh_host_ed25519_key"

# SSH sessions don't inherit the container's environment; pam_env reads
# /etc/environment. $1 is the file coding-entrypoint.sh wrote as coder.
if [ -n "${1:-}" ] && [ -f "$1" ]; then
	install -m 0644 "$1" /etc/environment
fi

# Firewall: deny all incoming, allow only $CODING_SSH_ALLOW to the sshd port.
{
	ufw --force reset
	ufw default deny incoming
	ufw default allow outgoing
	for ip in $allow; do
		ufw allow proto tcp from "$ip" to any port "$port" comment coding-sshd
	done
	ufw --force enable
} >>"$log" 2>&1 || {
	echo "coding-sshd: ufw failed (cap_add NET_ADMIN?), see $log; sshd not started" >&2
	exit 1
}

mkdir -p /run/sshd
/usr/sbin/sshd -p "$port" -E "$log"
echo "coding-sshd: sshd on :$port, allowed from: $allow" >&2
