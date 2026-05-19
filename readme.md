# Config & Dotfiles

A modular and automated configuration setup for Linux (optimized for Ubuntu/Debian). This repository contains installation scripts for various programming languages, development tools, and environment configurations, along with Docker support for testing or containerized development.

## 🚀 Features

### Languages & Runtimes
- **Go**: Version management via GVM and manual installation.
- **Node.js**: Latest NVM and Node.js (LTS/Stable).
- **Python**: Miniconda-based setup.
- **Lua**: Luarocks 3.11.1 built from source.

### Environment & Tools
- **Zsh**: Oh My Zsh, Powerlevel10k theme, and essential plugins (autosuggestions, syntax-highlighting, fzf-tab, etc.).
- **Neovim**: Custom Lua configuration (requires Neovim 0.10+).
- **i3wm**: Window manager configuration including Polybar and Nitrogen.
- **Tmux**: Terminal multiplexer setup with Tmuxinator.
- **Docker**: Automated installation and user group configuration.
- **Dunst**: Desktop notification daemon with custom configuration.
- **Fonts**: Automated Nerd Font installation.
- **Ghostty**: Terminal emulator setup.

## 🛠 Installation

### Local Machine
To install everything on your local machine, run the main initialization script:

```bash
chmod +x ./init.sh ./scripts/*.sh
./init.sh
```

You can also run individual scripts from the `scripts/` directory if you only need specific components (e.g., `./scripts/go.sh`).

### Docker (Containerized Environment)
You can build a Docker image to test the configuration or use it as a development container. The build process supports custom non-root users and verbose logging for easier troubleshooting.

Build the image:
```bash
./scripts/build_image.sh <your_username>
```
*If no username is provided, it defaults to `tuan`.*

Run the container:
```bash
docker run -it my-config
```

## 📂 Project Structure

- `scripts/`: Modular bash scripts for installing specific tools.
- `nvim/`: Neovim Lua configuration.
- `i3/` & `polybar/`: Window manager and status bar configs.
- `zsh/`: Zsh and Oh My Zsh customization.
- `dunst/`: Notification daemon configuration.
- `tmux/`: Tmux and Tmuxinator configurations.
- `Dockerfile`: Multi-stage build for the environment.

## 📝 Troubleshooting
If you encounter issues during the Docker build, the `scripts/build_image.sh` script uses `--progress=plain` to show full logs. Each installation step is separated into its own `RUN` command in the `Dockerfile` for precise error tracking and better layer caching.
