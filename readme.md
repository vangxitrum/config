# Config & Dotfiles

A modular and automated configuration setup for Linux (optimized for Ubuntu/Debian). This repository contains installation scripts for various programming languages, development tools, and environment configurations, along with Docker support for testing or containerized development.

## 🚀 Features

### Languages & Runtimes

- **Go**: Version management via GVM and manual installation.
- **Node.js**: Latest NVM and Node.js (LTS/Stable).
- **Python**: Miniconda-based setup.
- **Lua**: Luarocks 3.11.1 built from source.

### Environment & Tools

- **Zsh**: Oh My Zsh, Powerlevel10k theme, and essential plugins.
- **Neovim**: Custom Lua configuration (locked to **v0.12.2** with **lazy.nvim v11.17.5**).
- **i3wm**: Window manager configuration including Polybar and Nitrogen.
- **Input Method**: **Fcitx5** with Vietnamese Unikey. Toggle with **`Ctrl+Shift`**.
- **Docker**: Automated installation and robust user group configuration.
- **Dunst**: Desktop notification daemon with custom configuration.
    - `Ctrl+N`: Dismiss one notification at a time.
    - `Ctrl+Shift+N`: Restore the last dismissed notification.
- **Tmux Notification Jump**: Jump to the exact tmux window/pane that triggered a notification.
    - `Super+G` (i3) or `C-s g` (tmux): Jump to the pane referenced by the most recent notification.
    - `C-s b` (tmux): Jump back to the previous pane.
    - Any tool can opt in by adding `-c "tmux-target:$(tmux display -p '#{window_id}')"` to its `notify-send` call.
    - Claude Code hooks (`claude-notify.sh`) are pre-wired with persistent notifications and pane tracking.
- **s3cmd**: Command-line tool for managing Amazon S3 and other cloud storage.
- **Fonts**: Automated Nerd Font installation (FiraCode).
- **Ghostty**: Terminal emulator setup and configuration.

## 🛠 Installation

### Fresh Ubuntu Install (One-Liner)

For a completely automated setup on a fresh Ubuntu installation:

```bash
curl -sSL https://raw.githubusercontent.com/vangxitrum/config/master/bootstrap.sh | bash
```

### Local Machine (Manual)

To install components manually on your existing system:

```bash
git clone https://github.com/vangxitrum/config.git ~/setup/config
cd ~/setup/config
chmod +x ./init.sh ./scripts/*.sh
./init.sh
```

### Docker (Containerized Environment)

The environment is built using a **modular, stage-based Dockerfile** optimized for layer caching and maintainability. It handles UID/GID 1000 collisions automatically and supports custom non-root users.

Build the image:

```bash
./scripts/build_image.sh <your_username>
```

_If no username is provided, it defaults to `tuan`._

Run the container:

```bash
docker run -it my-config
```

## 📂 Project Structure

- `scripts/`: Modular bash scripts for installing specific tools and notification/jump utilities.
- `nvim/`: Neovim Lua configuration.
- `i3/` & `polybar/`: Window manager and status bar configs.
- `zsh/`: Zsh and Oh My Zsh customization.
- `dunst/`: Notification daemon configuration.
- `tmux/`: Tmux and Tmuxinator configurations (includes pane jump bindings and visual pane styling).
- `scripts/`: Includes `claude-notify.sh`, `tmux-jump-last-notify.sh`, `tmux-jump-back.sh`, and `dunst-close-one.sh`.
- `Dockerfile`: Multi-stage build for the environment.

## 📝 Troubleshooting

If you encounter issues during the Docker build, the `scripts/build_image.sh` script uses `--progress=plain` to show full logs. Each installation step is separated into its own `RUN` command in the `Dockerfile` for precise error tracking and better layer caching.
