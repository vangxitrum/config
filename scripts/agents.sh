#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Coding Agents (claude, codex, opencode, hermes)"
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

if command -v claude &>/dev/null; then
    print_status "claude already installed: $(claude --version)"
else
    print_status "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    print_success "Claude Code installed successfully!"
fi

if command -v codex &>/dev/null; then
    print_status "codex already installed: $(codex --version)"
else
    print_status "Installing Codex..."
    curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=true sh
    print_success "Codex installed successfully!"
fi

if command -v opencode &>/dev/null; then
    print_status "opencode already installed: $(opencode --version)"
else
    print_status "Installing opencode..."
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
    print_success "opencode installed successfully!"
fi

if command -v hermes &>/dev/null; then
    print_status "hermes already installed"
else
    print_status "Installing Hermes Agent..."
    curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh |
        bash -s -- --non-interactive
    print_success "Hermes Agent installed successfully!"
fi

# Logins are interactive, so they are left to the user.
echo ""
print_status "Sign in to each agent once:"
echo "  claude, codex login, opencode auth login, hermes setup"
echo ""

print_success "Coding agents setup complete!"
