#!/bin/sh
# coding-egress.sh - the coding container's only way out (compose.coding.yaml,
# `egress` service; runs there as PID 1, not on the host).
#
# `coding` and its `docker` daemon sit on an internal network with no route
# out and no outside DNS. This container is on that network and the normal
# one, and runs:
#   - squid on $SANDBOX_IP:3128: HTTP/HTTPS (and SSH via CONNECT) only to the
#     entries in /etc/egress/egress-allow.txt (config/coding, read-only) and
#     the unexpired ones in /run/egress-temp/temp (`coding allow` on the host).
#     Re-read every 10s; a change is checked with `squid -k parse` first.
#   - inbound SSH: published port 2222 -> coding:2222, only from
#     $CODING_SSH_ALLOW (iptables here, where the real client IP is visible).
#   - `host:<port>` entries: $SANDBOX_IP:<port> -> the host's <port>, which the
#     coding container reaches as host.docker.internal:<port>.
# Nothing in the coding container can change any of this: it has no access to
# this container, the allowlist or the temp file.
set -eu

ALLOW=/etc/egress/egress-allow.txt
TEMP=/run/egress-temp/temp
ACL=/etc/squid/egress-acl.conf
RUN=/run/egress
: "${CODING_IP:?}" "${SANDBOX_IP:?}"

log() { echo "egress: $*" >&2; }
mkdir -p "$RUN"

# ── inbound SSH ───────────────────────────────────────────────────────────────
iptables -N coding-ssh 2>/dev/null || iptables -F coding-ssh
for ip in $(printf '%s' "${CODING_SSH_ALLOW:-}" | tr ',' ' '); do
	iptables -A coding-ssh -s "$ip" -j ACCEPT
done
iptables -A coding-ssh -j DROP
iptables -C INPUT -p tcp --dport 2222 -j coding-ssh 2>/dev/null ||
	iptables -I INPUT -p tcp --dport 2222 -j coding-ssh
socat TCP-LISTEN:2222,fork,reuseaddr "TCP:$CODING_IP:2222" &
log "ssh :2222 -> coding, allowed from: ${CODING_SSH_ALLOW:-nobody}"

# ── allowlist ─────────────────────────────────────────────────────────────────
# Valid entries, one per line: permanent ones plus unexpired temporary ones.
entries() {
	now=$(date +%s)
	{
		sed 's/#.*//' "$ALLOW"
		[ -r "$TEMP" ] && awk -v now="$now" '$1 > now { print $2 }' "$TEMP"
	} | awk 'NF { print $1 }' |
		grep -E '^(host|[A-Za-z0-9.-]+|[0-9.]+/[0-9]+)(:[0-9]+)?$' | sort -u
}

# squid ACLs for entries on stdin: one port ACL per port ("web" = 80 and 443),
# dst (IPs/CIDRs) and dstdomain (names) lists per port. Names already covered
# by a ".suffix" entry for the same port are dropped (squid rejects them).
to_acl() {
	awk '
	{
		e = $0; port = "web"
		if (match(e, /:[0-9]+$/)) { port = substr(e, RSTART + 1); e = substr(e, 1, RSTART - 1) }
		if (e == "host") next
		t = (e ~ /^[0-9.]+(\/[0-9]+)?$/) ? "dst" : "dstdomain"
		n[port, t]++; v[port, t, n[port, t]] = e; ports[port] = 1
	}
	function covered(p, d,   i, s) {
		for (i = 1; i <= n[p, "dstdomain"]; i++) {
			s = v[p, "dstdomain", i]
			if (s ~ /^\./ && s != d && ("." d == s || substr(d, length(d) - length(s) + 1) == s)) return 1
		}
		return 0
	}
	END {
		for (p in ports) {
			print "acl p_" p " port " (p == "web" ? "80 443" : p)
			for (k = 1; k <= 2; k++) {
				t = (k == 1) ? "dst" : "dstdomain"; line = ""
				for (i = 1; i <= n[p, t]; i++) {
					d = v[p, t, i]
					if (t == "dstdomain" && covered(p, d)) continue
					line = line " " d
				}
				if (line == "") continue
				print "acl a_" p "_" t " " t line
				print "http_access allow p_" p " a_" p "_" t
			}
		}
	}'
}

cat >/etc/squid/squid.conf <<EOF
http_port $SANDBOX_IP:3128
pid_filename $RUN/squid.pid
cache deny all
via off
forwarded_for delete
shutdown_lifetime 1 seconds
logformat egress %{%Y-%m-%dT%H:%M:%S}tl %Ss/%>Hs %rm %ru
access_log /var/log/squid/access.log egress
include $ACL
http_access deny all
EOF
sed "s#^include .*#include $RUN/acl.check#" /etc/squid/squid.conf >"$RUN/squid.check.conf"

# ── host ports ────────────────────────────────────────────────────────────────
sync_forwards() {
	want=$(entries | sed -n 's/^host:\([0-9][0-9]*\)$/\1/p')
	for f in "$RUN"/fwd-*.pid; do
		[ -e "$f" ] || continue
		p=${f##*/fwd-}
		p=${p%.pid}
		printf '%s\n' "$want" | grep -qx "$p" && continue
		kill "$(cat "$f")" 2>/dev/null || true
		rm -f "$f"
		log "host:$p closed"
	done
	for p in $want; do
		f="$RUN/fwd-$p.pid"
		[ -e "$f" ] && kill -0 "$(cat "$f")" 2>/dev/null && continue
		socat "TCP-LISTEN:$p,bind=$SANDBOX_IP,fork,reuseaddr" "TCP:host.docker.internal:$p" &
		echo $! >"$f"
		log "host:$p open"
	done
}

# ── main loop ─────────────────────────────────────────────────────────────────
entries | to_acl >"$ACL"
squid -N -f /etc/squid/squid.conf &
squid_pid=$!
log "proxy on $SANDBOX_IP:3128, $(entries | wc -l) entries"
sync_forwards

while kill -0 "$squid_pid" 2>/dev/null; do
	sleep 10
	entries | to_acl >"$RUN/acl.check"
	if ! cmp -s "$RUN/acl.check" "$ACL"; then
		if squid -k parse -f "$RUN/squid.check.conf" >/dev/null 2>&1; then
			cp "$RUN/acl.check" "$ACL"
			squid -k reconfigure -f /etc/squid/squid.conf
			log "allowlist reloaded: $(entries | wc -l) entries"
		else
			log "allowlist change rejected by squid -k parse; keeping the previous one"
		fi
	fi
	sync_forwards
done
log "squid exited"
exit 1
