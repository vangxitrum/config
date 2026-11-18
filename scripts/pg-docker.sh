#!/usr/bin/env bash
# pg-docker.sh - run Postgres client tools (psql, pg_dump, ...) in Docker.
#
# scripts/postgres-client.sh symlinks ~/.local/bin/{psql,pg_dump,pg_restore,
# pg_dumpall} here; the tool to run is the name this was called by.
#
# $HOME, /tmp and $XDG_RUNTIME_DIR are mounted at their own paths, so
# `psql -f <temp file>` (vim-dadbod), ~/.pg_service.conf, ~/.psqlrc and the
# RAM copy from `pgpass unlock` ($PGPASSFILE) resolve as on the host.
# No -u: under rootless Docker container root is your own uid on the host.
#
# Networking: default bridge plus host.docker.internal -> host gateway (same as
# compose.coding.yaml). A DB container with a published port is reached at
# host.docker.internal:<port>; remote hosts work as usual. Tunnels bound to
# the host's real 127.0.0.1 are not reachable from rootless Docker.
set -euo pipefail

PG_VERSION="${PG_VERSION:-17}"
IMAGE="${PG_DOCKER_IMAGE:-postgres:$PG_VERSION-alpine}"
tool="$(basename "$0")"
case "$tool" in
psql | pg_dump | pg_restore | pg_dumpall) ;;
*) tool="psql" ;;
esac

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

args=(run --rm -i --log-driver none
	--add-host host.docker.internal:host-gateway
	-v "$HOME:$HOME" -v /tmp:/tmp -v "$runtime:$runtime"
	-e HOME -e TERM -e PAGER -e PSQL_PAGER -e LANG)
[ -t 0 ] && [ -t 1 ] && args+=(-t)

# Working directory only when the container can see it.
case "$PWD/" in
"$HOME"/* | /tmp/* | "$runtime"/*) args+=(-w "$PWD") ;;
*) args+=(-w "$HOME") ;;
esac

# Every libpq/psql variable (PGPASSFILE, PGSERVICEFILE, PGHOST, ...).
while IFS='=' read -r name _; do
	args+=(-e "$name")
done < <(env | grep -E '^PG[A-Z_]*=' || true)

exec docker "${args[@]}" "$IMAGE" "$tool" "$@"
