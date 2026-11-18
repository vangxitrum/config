#!/bin/bash
# pgpass.sh - Postgres passwords encrypted at rest, plain only while tmux runs.
#
# ~/.pgpass.age holds the passwords, encrypted with age to SSH public keys
# (~/.pgpass.recipients, one key per line: one per machine that may decrypt).
# `unlock` decrypts with the SSH private key ($PGPASS_IDENTITY) to $PGPASSFILE
# on tmpfs (RAM, never disk). Every tmux server that runs `unlock` (the main
# one, the dbui.sh one) gets a watcher; the copy is deleted when the last of
# those servers exits. libpq (psql, dadbod) reads PGPASSFILE, which
# home/.zshrc exports. Hosts/users live in ~/.pg_service.conf (no secrets).
#
# Usage: pgpass.sh init|add|edit|unlock|lock|status
#   init    create the SSH key if missing, encrypt an existing ~/.pgpass, delete it
#   add     prompt for a new connection: service entry + encrypted password
#   edit    edit all passwords in $EDITOR and re-encrypt
#   unlock  decrypt until the current tmux server (and any other unlocked one) exits
#   lock    delete the decrypted copy now
#   status  show whether passwords are unlocked

set -euo pipefail

ENC="$HOME/.pgpass.age"
RECIPIENTS="$HOME/.pgpass.recipients"
IDENTITY="${PGPASS_IDENTITY:-$HOME/.ssh/pgpass}"
PLAIN="$HOME/.pgpass"
SERVICES="${PGSERVICEFILE:-$HOME/.pg_service.conf}"
RUN_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
DEC="${PGPASSFILE:-$RUN_DIR/pgpass}"
# One line per watched tmux server: "<server pid> <watcher pid>".
WATCHERS="$RUN_DIR/pgpass.watchers"

die() { echo "pgpass: $*" >&2; exit 1; }

need_age() { command -v age >/dev/null || die "age not installed (run scripts/tools.sh)"; }
need_store() { [ -f "$ENC" ] || die "no $ENC (run 'pgpass init' first)"; }

# Plain passwords may only ever be written to tmpfs.
check_tmpfs() {
	[ "$(stat -f -c %T "$(dirname "$DEC")")" = "tmpfs" ] ||
		die "$(dirname "$DEC") is not tmpfs, refusing to write plain passwords there"
}

# Encrypting needs only public keys, so it never prompts.
encrypt_from() {
	age -R "$RECIPIENTS" -o "$ENC.tmp" "$1"
	chmod 600 "$ENC.tmp"
	mv "$ENC.tmp" "$ENC"
}

# Decrypting needs the private key (prompts if the key has a passphrase).
# Reuses the unlocked copy when there is one.
decrypt_to() {
	if [ -s "$DEC" ]; then
		cp "$DEC" "$1"
	else
		age -d -i "$IDENTITY" -o "$1" "$ENC"
	fi
}

# Scratch file on tmpfs, removed on exit. Global: the trap runs after return.
SCRATCH=""
make_scratch() {
	check_tmpfs
	umask 077
	SCRATCH="$(mktemp "$RUN_DIR/pgpass-edit.XXXXXX")"
	trap 'rm -f "$SCRATCH" "$ENC.tmp"' EXIT
}

stop_watchers() {
	if [ -f "$WATCHERS" ]; then
		local _server watcher
		while read -r _server watcher; do
			kill "$watcher" 2>/dev/null || true
		done <"$WATCHERS"
	fi
	rm -f "$WATCHERS" "$WATCHERS.lock"
}

# Keep the plain copy alive for the current tmux server: one watcher per
# server waits for it to exit, drops its line, and the last one out deletes
# the copy. Several servers (main tmux, dbui.sh's own) can share one unlock.
watch_server() {
	local server_pid
	server_pid="$(tmux display -p '#{pid}')"
	if [ -f "$WATCHERS" ] && grep -q "^$server_pid " "$WATCHERS"; then
		return
	fi
	setsid bash -c '
		tail --pid="$1" -f /dev/null
		exec 9>"$2.lock"
		flock 9
		grep -v "^$1 " "$2" >"$2.tmp" || true
		mv "$2.tmp" "$2"
		[ -s "$2" ] || rm -f "$3" "$2"
	' _ "$server_pid" "$WATCHERS" "$DEC" </dev/null >/dev/null 2>&1 &
	local watcher=$!
	(
		flock 9
		echo "$server_pid $watcher" >>"$WATCHERS"
	) 9>"$WATCHERS.lock"
	echo "pgpass: unlocked until tmux server $server_pid (and any other unlocked one) exits"
}

# pgpass fields escape ':' and '\' with a backslash.
pgpass_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/:/\\:/g'; }

cmd_init() {
	need_age
	[ -e "$ENC" ] && die "$ENC already exists; use 'add' or 'edit'"
	if [ ! -f "$IDENTITY" ]; then
		echo "Creating SSH key $IDENTITY for pgpass (a passphrase is recommended):"
		ssh-keygen -t ed25519 -C "pgpass@$(hostname)" -f "$IDENTITY"
	fi
	[ -f "$RECIPIENTS" ] || cp "$IDENTITY.pub" "$RECIPIENTS"
	chmod 600 "$RECIPIENTS"
	make_scratch
	if [ -f "$PLAIN" ]; then
		cp "$PLAIN" "$SCRATCH"
	fi
	encrypt_from "$SCRATCH"
	echo "Verifying the encrypted copy decrypts with $IDENTITY..."
	age -d -i "$IDENTITY" "$ENC" | cmp -s - "$SCRATCH" ||
		{ rm -f "$ENC"; die "verification failed, nothing changed"; }
	if [ -f "$PLAIN" ]; then
		shred -u "$PLAIN" 2>/dev/null || rm -f "$PLAIN"
		echo "Encrypted $PLAIN to $ENC and deleted the plain file."
	else
		echo "Created empty $ENC."
	fi
	echo "Next: 'pgpass unlock' inside tmux, 'pgpass add' for new connections."
}

ask() { # ask <var> <prompt> [default]
	local reply
	read -rp "$2${3:+ [$3]}: " reply
	printf -v "$1" '%s' "${reply:-${3:-}}"
}

cmd_add() {
	need_age
	need_store
	local name host port db user pass pass2 ro
	ask name "Service name (e.g. app-prod)"
	[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || die "service name may only use letters, digits, . _ -"
	if [ -f "$SERVICES" ] && grep -qxF "[$name]" "$SERVICES"; then
		die "service [$name] already exists in $SERVICES"
	fi
	ask host "Host (localhost for an SSH tunnel)"
	ask port "Port" 5432
	ask db "Database"
	ask user "User"
	read -rsp "Password: " pass
	echo
	read -rsp "Password again: " pass2
	echo
	[ "$pass" = "$pass2" ] || die "passwords do not match"
	ask ro "Read-only session with 30s statement timeout? (y/n)" y
	[ -n "$host" ] && [ -n "$db" ] && [ -n "$user" ] || die "host, database and user are required"

	make_scratch
	decrypt_to "$SCRATCH"
	printf '%s:%s:%s:%s:%s\n' "$(pgpass_escape "$host")" "$(pgpass_escape "$port")" \
		"$(pgpass_escape "$db")" "$(pgpass_escape "$user")" "$(pgpass_escape "$pass")" >>"$SCRATCH"
	encrypt_from "$SCRATCH"
	[ -s "$DEC" ] && cp "$SCRATCH" "$DEC"

	{
		[ -s "$SERVICES" ] && echo
		echo "[$name]"
		echo "host=$host"
		echo "port=$port"
		echo "dbname=$db"
		echo "user=$user"
		if [[ "$ro" =~ ^[Yy] ]]; then
			echo "options=-c default_transaction_read_only=on -c statement_timeout=30s"
		fi
	} >>"$SERVICES"
	chmod 600 "$SERVICES"
	echo "pgpass: added [$name] (restart nvim to see it in dadbod-ui)"

	if [ -s "$DEC" ] && command -v psql >/dev/null; then
		echo "Testing connection..."
		psql "service=$name" -Atc 'select 1' >/dev/null && echo "pgpass: [$name] connects OK"
	else
		echo "Run 'pgpass unlock' and 'psql service=$name -c \"select 1\"' to test it."
	fi
}

cmd_edit() {
	need_age
	need_store
	make_scratch
	decrypt_to "$SCRATCH"
	local before
	before="$(sha256sum "$SCRATCH")"
	# $EDITOR may carry flags (`code -w`), so split it into words.
	local -a editor
	read -ra editor <<<"${EDITOR:-vi}"
	"${editor[@]}" "$SCRATCH"
	if [ "$(sha256sum "$SCRATCH")" = "$before" ]; then
		echo "pgpass: no changes"
		return
	fi
	encrypt_from "$SCRATCH"
	[ -s "$DEC" ] && cp "$SCRATCH" "$DEC"
	echo "pgpass: saved"
}

cmd_unlock() {
	need_age
	need_store
	[ -n "${TMUX:-}" ] || die "run inside tmux: passwords live only as long as the tmux server"
	if [ -s "$DEC" ]; then
		watch_server
		return
	fi
	check_tmpfs
	umask 077
	age -d -i "$IDENTITY" -o "$DEC.tmp" "$ENC" || { rm -f "$DEC.tmp"; die "decrypt failed"; }
	mv "$DEC.tmp" "$DEC"
	watch_server
}

cmd_lock() {
	stop_watchers
	rm -f "$DEC"
	echo "pgpass: locked"
}

cmd_status() {
	if [ -s "$DEC" ]; then
		echo "unlocked ($DEC)"
	else
		echo "locked"
	fi
}

case "${1:-status}" in
init) cmd_init ;;
add) cmd_add ;;
edit) cmd_edit ;;
unlock) cmd_unlock ;;
lock) cmd_lock ;;
status) cmd_status ;;
-h | --help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//' ;;
*) die "unknown command: $1 (try --help)" ;;
esac
