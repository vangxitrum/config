#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Coding Agents (claude, codex, opencode, pi, hermes)"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# home/.profile and home/.zshrc already put ~/.local/bin and ~/.opencode/bin on
# PATH. Exporting them here makes the installers see that and leave the
# (symlinked, repo-tracked) shell rc files alone.
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# Usage: agents.sh [claude|codex|opencode|pi|hermes ...]  (default: all).
# Versions: CLAUDE_VERSION, CODEX_VERSION, OPENCODE_VERSION, PI_VERSION, HERMES_COMMIT
# (Dockerfile.coding pins them); unset installs the latest.
# Dockerfile.coding installs each in its own build stage.
ONLY=("$@")
want() { [ "${#ONLY[@]}" -eq 0 ] || [[ " ${ONLY[*]} " == *" $1 "* ]]; }

if ! want claude; then
    :
elif command -v claude &>/dev/null; then
    print_status "claude already installed: $(claude --version)"
else
    print_status "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash -s ${CLAUDE_VERSION:+"$CLAUDE_VERSION"}
    print_success "Claude Code installed successfully!"
fi

if ! want codex; then
    :
elif command -v codex &>/dev/null; then
    print_status "codex already installed: $(codex --version)"
else
    print_status "Installing Codex..."
    curl -fsSL https://chatgpt.com/codex/install.sh |
        CODEX_NON_INTERACTIVE=true sh -s -- ${CODEX_VERSION:+--release "$CODEX_VERSION"}
    print_success "Codex installed successfully!"
fi

if ! want opencode; then
    :
elif command -v opencode &>/dev/null; then
    print_status "opencode already installed: $(opencode --version)"
else
    print_status "Installing opencode..."
    curl -fsSL https://opencode.ai/install |
        bash -s -- --no-modify-path ${OPENCODE_VERSION:+--version "$OPENCODE_VERSION"}
    print_success "opencode installed successfully!"
fi

if ! want pi; then
    :
elif command -v pi &>/dev/null; then
    print_status "pi already installed: $(pi --version)"
elif ! command -v npm &>/dev/null; then
    print_error "pi needs Node >= 22.19 and npm (scripts/node.sh); skipping"
else
    # Into ~/.local (bin/pi), not the nvm tree, so it survives Node upgrades.
    print_status "Installing pi..."
    npm install -g --prefix "$HOME/.local" "@earendil-works/pi-coding-agent@${PI_VERSION:-latest}"
    print_success "pi installed successfully!"
fi

if ! want hermes; then
    :
elif command -v hermes &>/dev/null; then
    print_status "hermes already installed"
else
    print_status "Installing Hermes Agent..."
    # Script and checkout from the same commit when pinned.
    curl -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_COMMIT:-main}/scripts/install.sh" |
        bash -s -- --non-interactive ${HERMES_COMMIT:+--commit "$HERMES_COMMIT"}
    print_success "Hermes Agent installed successfully!"
fi

# Logins are interactive, so they are left to the user.
echo ""
print_status "Sign in to each agent once:"
echo "  claude, codex login, opencode auth login, pi (then /login), hermes setup"
echo ""

print_success "Coding agents setup complete!"
