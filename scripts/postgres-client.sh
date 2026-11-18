#!/bin/bash
# PostgreSQL client tools.
#
#   postgres-client.sh           Docker mode (no sudo): pull postgres:<ver>-alpine
#                                and link psql, pg_dump, pg_restore, pg_dumpall in
#                                ~/.local/bin to scripts/pg-docker.sh.
#   postgres-client.sh --native  apt install from the PGDG repo (needs sudo; used
#                                by the Docker images, which have no Docker daemon).

set -e # Exit on error

# psql major version. A client talks to servers of its own version and older
# (back to 9.2), so keep this >= the newest server you connect to.
# Keep in sync with PG_VERSION in scripts/pg-docker.sh.
PG_VERSION=17
TOOLS=(psql pg_dump pg_restore pg_dumpall)

MODE=docker
[ "${1:-}" = "--native" ] && MODE=native

echo "=================================="
echo "PostgreSQL client (psql $PG_VERSION, $MODE)"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

install_native() {
    # Ubuntu only ships psql 16, so use the official PGDG apt repository.
    if dpkg -s "postgresql-client-$PG_VERSION" &>/dev/null; then
        print_status "postgresql-client-$PG_VERSION already installed"
    else
        print_status "Adding the PGDG apt repository..."
        . /etc/os-release
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc |
            sudo tee /etc/apt/keyrings/pgdg.asc >/dev/null
        sudo chmod go+r /etc/apt/keyrings/pgdg.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/pgdg.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" |
            sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null
        sudo apt-get update
        print_status "Installing postgresql-client-$PG_VERSION..."
        sudo apt-get install -y "postgresql-client-$PG_VERSION"
        print_success "postgresql-client-$PG_VERSION installed"
    fi
    echo ""
    print_success "$(/usr/bin/psql --version) ready (reads ~/.pg_service.conf and ~/.pgpass)"
}

install_docker() {
    local wrapper bin
    wrapper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pg-docker.sh"
    bin="$HOME/.local/bin"

    if ! docker info &>/dev/null; then
        print_error "docker is not reachable (rootless Docker running? see scripts/docker.sh)"
        exit 1
    fi
    print_status "Pulling postgres:$PG_VERSION-alpine..."
    docker pull -q "postgres:$PG_VERSION-alpine" >/dev/null

    chmod +x "$wrapper"
    mkdir -p "$bin"
    for tool in "${TOOLS[@]}"; do
        local target="$bin/$tool"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$wrapper" ]; then
            continue
        fi
        if [ -e "$target" ] || [ -L "$target" ]; then
            mv "$target" "$target.bak.$(date +%s)"
            print_warn "moved existing $target aside"
        fi
        ln -s "$wrapper" "$target"
    done
    print_success "linked ${TOOLS[*]} in $bin -> $wrapper"

    echo ""
    print_success "$("$bin/psql" --version) ready via Docker (reads ~/.pg_service.conf and \$PGPASSFILE)"
}

if [ "$MODE" = native ]; then
    install_native
else
    install_docker
fi
