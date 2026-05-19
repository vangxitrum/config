#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Zsh Installation & Configuration"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on Ubuntu/Debian
if [ -f /etc/os-release ]; then
  . /etc/os-release
  print_status "Detected OS: $ID $VERSION_ID"
else
  print_warning "Cannot detect OS. Proceeding anyway..."
fi

# Install Zsh and dependencies
echo "=================================="
echo "Installing Zsh and Dependencies"
echo "=================================="

if command -v zsh &>/dev/null; then
  ZSH_VERSION=$(zsh --version)
  print_status "Zsh is already installed: $ZSH_VERSION, skipping installation..."
else
  print_status "Updating package lists..."
  sudo apt-get update
  print_status "Installing Zsh and dependencies..."
  sudo apt-get install -y zsh curl git wget unzip
fi

print_success "Zsh installed: $(zsh --version)"
echo ""

# Install Oh My Zsh
echo "=================================="
echo "Installing Oh My Zsh"
echo "=================================="

if [ -d "$HOME/.oh-my-zsh" ]; then
  print_status "Oh My Zsh is already installed, skipping..."
else
  print_status "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

print_success "Oh My Zsh installed"
echo ""

# Install FZF
echo "=================================="
echo "Installing FZF (Fuzzy Finder)"
echo "=================================="

if [ -d "$HOME/.fzf" ]; then
  print_status "FZF already installed"
else
  print_status "Cloning FZF repository..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  print_status "Installing FZF..."
  "$HOME/.fzf/install" --all --no-bash --no-fish
  print_success "FZF installed"
fi
echo ""

# Install popular plugins
echo "=================================="
echo "Installing Popular Plugins"
echo "=================================="

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  print_status "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  print_success "zsh-autosuggestions installed"
else
  print_status "zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  print_status "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  print_success "zsh-syntax-highlighting installed"
else
  print_status "zsh-syntax-highlighting already installed"
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
  print_status "Installing zsh-completions..."
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
  print_success "zsh-completions installed"
else
  print_status "zsh-completions already installed"
fi

# zsh-history-substring-search
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
  print_status "Installing zsh-history-substring-search..."
  git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
  print_success "zsh-history-substring-search installed"
else
  print_status "zsh-history-substring-search already installed"
fi

# zsh-z (better z)
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-z" ]; then
  print_status "Installing zsh-z (directory jumper)..."
  git clone https://github.com/agkozak/zsh-z "$ZSH_CUSTOM/plugins/zsh-z"
  print_success "zsh-z installed"
else
  print_status "zsh-z already installed"
fi

# fzf-tab (fzf integration for tab completion)
if [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]; then
  print_status "Installing fzf-tab..."
  git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
  print_success "fzf-tab installed"
else
  print_status "fzf-tab already installed"
fi

echo ""

# Install Powerlevel10k theme
echo "=================================="
echo "Installing Powerlevel10k Theme"
echo "=================================="

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  print_status "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
  print_success "Powerlevel10k installed"
else
  print_status "Powerlevel10k already installed"
fi

echo ""

# Configure .zshrc
echo "=================================="
echo "Configuring .zshrc"
echo "=================================="

if [ -f "$HOME/.zshrc" ]; then
  # Backup existing .zshrc
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
  print_status "Backup created: ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"

  # Update theme to powerlevel10k
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"

  # Update plugins - comprehensive list with z, fzf, and useful plugins
  sed -i 's/^plugins=.*/plugins=(\n  git\n  zsh-autosuggestions\n  zsh-syntax-highlighting\n  zsh-completions\n  zsh-history-substring-search\n  zsh-z\n  fzf\n  fzf-tab\n  docker\n  docker-compose\n  kubectl\n  npm\n  node\n  python\n  pip\n  command-not-found\n  colored-man-pages\n  extract\n  sudo\n )/' "$HOME/.zshrc"

  # Add fpath for zsh-completions
  if ! grep -q "fpath+=" "$HOME/.zshrc"; then
    sed -i '/^source \$ZSH\/oh-my-zsh.sh/i fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src' "$HOME/.zshrc"
  fi

  # Add FZF configuration
  if ! grep -q "FZF configuration" "$HOME/.zshrc"; then
    cat >>"$HOME/.zshrc" <<'EOF'


sudo chsh -s /bin/zsh

# FZF configuration
export FZF_DEFAULT_COMMAND='find . -type f'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'cat {}' --preview-window down:3:wrap"
export FZF_ALT_C_OPTS="--preview 'ls {}'"

# FZF key bindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Useful aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Quick directory navigation with z
# Usage: z <partial_directory_name>
# Example: z doc  (jumps to /home/user/Documents)
EOF
  fi

  print_success ".zshrc configured with all plugins and FZF"
else
  print_error ".zshrc not found"
fi

cp ./.profile $HOME

cp ./.zshrc $HOME

echo ""

# Set Zsh as default shell
echo "=================================="
echo "Setting Default Shell"
echo "=================================="

# Show installation summary
echo "=================================="
print_success "Installation Complete!"
echo "=================================="
echo ""
print_status "Installed components:"
echo "  ✓ Zsh"
echo "  ✓ Oh My Zsh"
echo "  ✓ FZF (Fuzzy Finder)"
echo "  ✓ zsh-autosuggestions"
echo "  ✓ zsh-syntax-highlighting"
echo "  ✓ zsh-completions"
echo "  ✓ zsh-history-substring-search"
echo "  ✓ zsh-z (directory jumper)"
echo "  ✓ fzf-tab"
echo "  ✓ Powerlevel10k theme"
echo ""
print_status "Enabled built-in plugins:"
echo "  • git, docker, docker-compose, kubectl"
echo "  • npm, node, python, pip"
echo "  • command-not-found, colored-man-pages"
echo "  • extract, sudo, web-search"
echo ""
print_status "Next steps:"
echo "  1. Restart your terminal or run: zsh"
echo "  2. Powerlevel10k configuration wizard will start automatically"
echo "  3. Follow the prompts to customize your prompt"
echo ""
print_status "Useful commands:"
echo "  • Edit config: nano ~/.zshrc"
echo "  • Reload config: source ~/.zshrc"
echo "  • Update Oh My Zsh: omz update"
echo "  • Configure P10k: p10k configure"
echo ""
print_status "FZF shortcuts:"
echo "  • Ctrl+T: Search files"
echo "  • Ctrl+R: Search command history"
echo "  • Alt+C: Change directory"
echo ""
print_status "Z (directory jumper) usage:"
echo "  • z doc      → jump to ~/Documents"
echo "  • z down     → jump to ~/Downloads"
echo "  • z proj web → jump to ~/Projects/website"
echo ""
print_status "Recommended: Install a Nerd Font for best experience"
echo "  • FiraCode Nerd Font (use the font installer script)"
echo ""
print_warning "If default shell changed, log out and log back in to use Zsh"
