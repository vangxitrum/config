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
    - From the coding container: agents write notifications to `$XDG_RUNTIME_DIR/agent-notify` (mounted at `/run/agent-notify`) and `scripts/agent-notify-bridge.sh`, started by i3, shows them on the host's dunst. Inside the container the default mode is dunst (`C-s N` toggles tmux banners); `C-s g` jumps within the container's tmux, while `Super+G` on the host cannot.
- **s3cmd**: Command-line tool for managing Amazon S3 and other cloud storage.
- **Git tools**: GitHub CLI (`gh`, official apt repo) and `lazygit`.
    - Lazygit config (`config/lazygit/config.yml`): Catppuccin theme, `C-o` opens files in Neovim, `C-a` in the files panel drafts a commit message with Claude (headless, hooks disabled so session style rules don't leak into the message).
- **CLI tools**: `btop`, `lazydocker`.
- **SSH keys on demand** (`sshkey`, `scripts/sshkey.sh`): no agent runs at login and none is exposed to GUI apps. `sshkey` starts one on `$XDG_RUNTIME_DIR/ssh-agent.sock` (shared by every terminal) and lets you pick keys with fzf (or `ALL`); `sshkey all`, `sshkey github hub`, `sshkey -t 4h …` (expire), `sshkey ls`, `sshkey rm`, `sshkey stop`. Passphrases are asked in the terminal.
    - `sshkey setup` (one time, no sudo): masks the session's automatic agents (GNOME Keyring's `gcr-ssh-agent`, gpg-agent's ssh socket, systemd `ssh-agent`). The keyring's password store for Slack/browsers is untouched.
- **psql 17 in Docker** (no sudo): `scripts/postgres-client.sh` links `psql`, `pg_dump`, `pg_restore` and `pg_dumpall` in `~/.local/bin` to `scripts/pg-docker.sh`, which runs them from `postgres:17-alpine` (bump `PG_VERSION` in both scripts to match your newest server). `$HOME`, `/tmp` and `$XDG_RUNTIME_DIR` are mounted at the same paths, so dadbod, `~/.pg_service.conf` and `$PGPASSFILE` work unchanged. `--native` installs from the PGDG apt repo instead (used by the Docker images).
    - Local DBs: publish the DB container's port and use `host=host.docker.internal` in `~/.pg_service.conf`; the same entry works from the coding container. Under rootless Docker this needs `scripts/docker.sh`, which points `host-gateway` at the host's loopback (`10.0.2.2`) and so also reaches SSH tunnels on your `localhost`.
- **Postgres passwords** (`pgpass`, `scripts/pgpass.sh`): stored in `~/.pgpass.age`, encrypted with `age` to the SSH keys listed in `~/.pgpass.recipients`. Hosts and users stay in `~/.pg_service.conf`.
    - `pgpass init`: one time, create the `~/.ssh/pgpass` key if missing, encrypt an existing plain `~/.pgpass` and delete it.
    - `pgpass add`: prompt for a new connection, write the service entry and the encrypted password, then test it.
    - `pgpass unlock` (inside tmux): decrypt with the SSH key to RAM (`$PGPASSFILE` on tmpfs) until the tmux server exits. Several tmux servers can unlock (the main one and the dbui one); the copy is deleted when the last of them exits.
    - `pgpass edit` / `pgpass lock` / `pgpass status`.
    - Another machine: append its SSH public key to `~/.pgpass.recipients`, run `pgpass edit` (re-encrypts to every key), copy `~/.pgpass.age` and `~/.pg_service.conf` over, and set `PGPASS_IDENTITY` there if its key is not `~/.ssh/pgpass`.
- **vim-dadbod-ui** (Neovim): `<leader>su` toggles the DB tree, `Ctrl+Enter` runs the query (normal/insert) or selection (visual). `<leader>?` (or `?` in the tree) shows a which-key popup with only that DB buffer's keys. Connections are read from `~/.pg_service.conf`; tables and columns autocomplete in SQL buffers.
    - Own window: `$mod+Shift+d` (or `dbui` in a shell) opens it in a separate kitty window on i3 workspace `4:db`, inside its own tmux server (`tmux -L dbui`, separate from your main tmux; unlocks passwords first). Pressing it again focuses the open window. Over SSH, `dbui` opens the same session in your terminal (detach with prefix `d`; it keeps running). It starts in the saved-queries folder, `config/db_ui/` in this repo (synced with git; `connections.json` there is ignored). i3 also starts it on login (in the background, so you stay on workspace 1).
- **Coding agents**: Claude Code, Codex, opencode, Hermes Agent (official installers; sign in once after install).
- **Fonts**: Automated Nerd Font installation (FiraCode).
- **kitty**: Terminal emulator (`$mod+Enter`), config in `config/kitty/kitty.conf`. `scripts/kitty.sh` installs it under `~/.local/kitty.app` when it is missing.

## 🛠 Installation

### Fresh Ubuntu Install (One-Liner)

For a completely automated setup on a fresh Ubuntu installation:

```bash
curl -sSL https://raw.githubusercontent.com/vangxitrum/config/main/bootstrap.sh | bash
```

### Headless Machine (Server / VPS)

Skip the desktop-only parts (i3, kitty, Dunst, fonts, Fcitx5, flameshot, xclip):

```bash
curl -sSL https://raw.githubusercontent.com/vangxitrum/config/main/bootstrap.sh | bash -s -- --headless
# or, from a clone:
./init.sh --headless
```

Desktop configs are still linked by `install.sh`; they are inert without a display.
Desktop notifications (Dunst, the tmux notification jump) do not work headless.

### Local Machine (Manual)

To install components manually on your existing system:

```bash
git clone https://github.com/vangxitrum/config.git ~/work/config
cd ~/work/config
chmod +x ./init.sh ./install.sh ./scripts/*.sh
./init.sh
```

> The repo is expected at `~/work/config` — tmux, i3, and Claude Code hooks
> reference scripts there by absolute path.

### User-local i3

`./scripts/i3.sh` downloads i3 and the tools its config starts (i3status,
i3lock, dmenu, dex, xss-lock, Polybar, Dunst, picom, Flameshot, and Nitrogen
on Ubuntu releases that package it, Fcitx5 with Unikey, and PyICU for the
lunar dates in the Polybar calendar) from the configured Ubuntu package
repositories into `~/.local/lib/i3-desktop` and links the commands into
`~/.local/bin`. Only libraries missing from the system are bundled. Run it as
your regular user; it needs no sudo. Run it again to update. `./init.sh` uses
the same installer and still installs other system prerequisites through APT.

Fcitx5 answers as IBus, so GTK, Qt, Electron and kitty apps reach it through the
IBus modules Ubuntu already ships; `start-i3` sets `GTK_IM_MODULE=ibus`,
`QT_IM_MODULE=ibus`, `GLFW_IM_MODULE=ibus` and `XMODIFIERS=@im=fcitx` for the
session. `./scripts/fcitx5.sh` writes its settings (Telex, `Ctrl+Shift` toggle).

Firefox allows one running copy per profile. If Firefox is still open in a
GNOME session, launching it from i3 opens the window over in GNOME instead, so
close it there (or log out of GNOME) before `start-i3`.

`./scripts/dunst.sh` registers Dunst as your session's notification daemon
(`~/.local/share/dbus-1/services`). Other notification daemons stay installed but unused.

Run `./install.sh` to link the desktop configs. To start i3, switch to a text
console (`Ctrl+Alt+F3`), log in, and run `start-i3`. It starts the system Xorg
(`xserver-xorg-core`, the only system package needed) without root, using the
bundled xinit and keyboard/mouse driver. The Xorg log is
`~/.local/state/Xorg.<n>.log`. Exiting i3 returns to the console. The display
manager's session menu is left untouched, so i3 is not listed there.

### Linking Only (configs already installed)

If the tools are already installed and you only want to (re)link the dotfiles:

```bash
./install.sh
```

`install.sh` symlinks `config/<dir>` → `~/.config/<dir>` and `home/<dotfile>` →
`~/<dotfile>`. Existing real files are backed up to `*.bak.<timestamp>`;
editing a config in this repo takes effect live. `fcitx5` is excluded — it is
generated by `scripts/fcitx5.sh`.

### Updating a Machine

Because configs are symlinked, edits on any machine land in this repo's
working tree. Commit and push them there, then on every other machine:

```bash
./update.sh    # or the `cfgup` alias
```

`update.sh` refuses to run with uncommitted changes, then does `git pull
--rebase`, re-runs `install.sh` (links any new config dirs), restores nvim
plugins to `lazy-lock.json`, and reloads tmux and i3 if they are running.

A new zsh prints one `config:` line when this machine has uncommitted or
unpushed config edits, or is behind origin (remote checked in the background
at most every 6h).

### Per-Machine Values

Anything that differs between machines lives in a gitignored `*.local` file,
created by `install.sh` from the committed `*.local.example` template:

- `config/i3/config.local` — monitor names (`$monitor_left`, `$monitor_right`).
  It must end with `include ~/.config/i3/monitors.conf` (the template does), which
  sets the screen order and puts workspaces on their monitors. A `config.local`
  made before this change needs that line added.

tmuxinator layouts are per-machine too: `config/tmuxinator/*` is gitignored, so a
new layout stays on the machine that created it. The shared layouts already
tracked keep syncing; add a new shared one with `git add -f`.

### Install only the tmux config

Run this from the checkout as your regular user:

```bash
./install-tmux.sh
```

The script installs `~/.tmux.conf` and its helper scripts, and backs up an
existing `~/.tmux.conf` when it changes. It uses TPM if it is already installed
at `~/.config/tmux/plugins/tpm`. Run the installer again after updating the
checkout. Reload a running server with `tmux source-file ~/.tmux.conf`.

### Headless coding image

The coding image starts tmux and Zsh as a non-root user with the repo's
terminal dotfiles, including the full tmux, Neovim, and Lazygit configs. It
includes NVM, Miniconda, Go, LuaRocks, PostgreSQL client, coding agents, and
the Docker CLI. Docker commands need access to a Docker daemon. Desktop
components such as i3, Polybar, kitty, Dunst, and Fcitx5 are excluded.

The Dockerfile is multi-stage: Zsh, Node, Miniconda, Go tools, Neovim and
each coding agent build in parallel stages that copy only the script they run,
and the repo's dotfiles and scripts are copied last. Editing a helper script
rebuilds in seconds; editing `scripts/agents.sh` reinstalls only the agents.

To add apt packages, list them in `config/coding/apt-packages.txt` (one per
line) and rebuild; only that step and the final layers run again. Packages
installed with `apt-get` inside a running container are lost when it exits.

```bash
docker build -f Dockerfile.coding \
  --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" \
  -t config-coding .
```

From the config checkout, start a session with persistent state. Set
`CODING_WORKSPACE` to the code folder to mount (default `~/work`, at the same path inside).

```bash
CODING_WORKSPACE=/absolute/path/to/project docker compose -f compose.coding.yaml run --rm coding
```

#### SSH into the container

The container runs an SSH server on port 2222 that accepts only the keys in
your host `~/.ssh/authorized_keys` (no passwords). The container runs as
root, which under rootless Docker *is* your host user: files it writes to the
workspace or `~/.claude` stay owned by you (the `coder` user would be a foreign
subuid that can't write bind mounts). Log in as `root`; its home is `/home/coder`. Port 2222 is
published by the `egress` service, which drops every address except
`CODING_SSH_ALLOW` (default `10.0.0.40`; space/comma separated, CIDRs work) and
forwards the rest to the container, whose ufw accepts only `egress`. Port
forwarding (`-L`/`-R`/`-D`) and agent forwarding are off.

```bash
CODING_WORKSPACE=/absolute/path/to/project docker compose -f compose.coding.yaml up -d
ssh -p 2222 root@<this machine>       # from 10.0.0.40, then: tmux attach -t coding
docker compose -f compose.coding.yaml exec coding tmux attach -t coding   # locally
```

- Rootless Docker needs `scripts/docker.sh` once: its `slirp4netns` port driver passes the real client IP to `egress` (with the default driver every client looks like `172.17.0.1`, and nobody gets in).
- `authorized_keys` is read through `AuthorizedKeysCommand`; edits apply on the next login.
- The host key lives in the `sshd-keys` volume, so rebuilds don't trigger known_hosts warnings. Logs: `/var/log/coding-sshd.log`. `CODING_SSHD=0` turns it off.

Compose creates named volumes for state that should survive rebuilds:
`sshd-keys` holds the SSH host key, and `nvim-data`, `nvim-state` and
`nvim-cache` keep Neovim's plugins, Mason tools and treesitter parsers, so a
new image doesn't reinstall them (`docker volume rm config_nvim-data` for a
clean reinstall). The Zsh volume starts with the repo’s
`~/.zshrc` and saves subsequent edits and shell history. The Claude Code and
Codex volumes keep their local settings, sessions, memory, and file-based
login state. Sign in inside the container on first use with `claude auth login`.
If prompted again, run `claude auth status` in a fresh container started with the
same Compose project name. Claude stores its login and onboarding state under
`CLAUDE_CONFIG_DIR`. [Claude Code dev container docs](https://code.claude.com/docs/en/devcontainer#persist-authentication-and-settings-across-rebuilds)

Set `CODING_CLAUDE_STATE="$HOME/.claude"` when launching Compose to use your
host Claude directory instead. That mount shares credentials and allows Claude
to write to the host directory. Claude may prompt for first-time setup in the
container because a standard host install keeps `.claude.json` outside that
directory. Claude history is indexed by project path, so history recorded under
a host path appears under the same path (code is mounted at its host path).

With rootless Docker, add `--user 0:0` before `coding` in the Compose run
command. Rootless Docker maps that container UID to your host user, which gives
the terminal access to owner-only files in the bind mounts. This runs the
terminal as root within the container's user namespace.

Compose mounts `~/.ssh` read-only, so nothing in the container can add a key
to your host `authorized_keys` or rewrite `config`. Edit those on the host.
New host keys are saved in the `ssh-state` volume (`config/coding/ssh_config`);
hosts in your host `known_hosts` are still checked. Set `CODING_SSH_DIR` to an
absolute path to use a different SSH directory. Use `ssh-agent zsh` in a tmux
pane when you want to cache a decrypted key, then run `ssh-add ~/.ssh/<key>` in
the new shell. The agent serves that shell and its child processes. Run `exit`
to stop it.

`docker` inside the container talks to its own daemon, the `docker` Compose
service (`docker:dind`, data in the `dind-data` volume), not the host's: the
host socket would give anything in the container your host user. Its
containers, images and published ports are separate from the host's; reach a
published port from the coding container as `docker:<port>`. Your code is
mounted at the same path in both (with the same read-only overlays), so
`-v ~/work/...` works.

Outbound network: `coding` and its `docker` daemon sit on an internal network
with no route out and no outside DNS. The `egress` service
(`scripts/coding-egress.sh`) is the only way out: an HTTP(S) proxy (also used by
SSH via `nc -X connect`) that lets through only `config/coding/egress-allow.txt`
plus temporary entries. It also forwards inbound SSH (only from
`CODING_SSH_ALLOW`) and, for `host:<port>` entries, a host port that the
container reaches as `host.docker.internal:<port>`. Manage it from the host;
the container can't approve its own access:

```bash
coding blocked                          # what was denied recently
coding allow api.example.com 30m        # temporary (default 1h); s/m/h/d
coding allow kibana.example.com:5601 host:5432 2h
coding allow --permanent grafana.example.com   # appends to egress-allow.txt
coding allow ls                         # temporary entries and time left
coding deny api.example.com             # drop it (temporary and permanent)
```

Changes apply within ~10s. Tools that ignore `HTTPS_PROXY` simply can't
connect. Containers you start inside get the proxy from
`~/.docker/config.json`.

Code: `~/work` (`CODING_WORKSPACE`) is mounted writable at the same path, so
you can work across all repos in one container (`coding` refuses `~` or `/`).
The host trusts some of it, so these are read-only inside (also for
`docker run -v`): this repo (your dotfiles are symlinks into it; edit it on the
host), and the vault's `.obsidian` (plugins), `.git` (obsidian-git) and
`.agent/memory`. Git config and hooks of every other repo stay writable, so
the host's git goes through `scripts/git-guard.sh`: it refuses to run in a repo
under `~/work` whose git config or hooks could run a program (`core.fsmonitor`,
pagers, `sshCommand`, filters, hooks…) until you approve exactly that.
lazygit and nvim's gitsigns use it too. Link it once, on the host only:

```bash
ln -sfn ~/work/config/scripts/git-guard.sh ~/.local/bin/git
ln -sfn ~/work/config/scripts/git-guard.sh ~/.local/bin/git-guard
coding audit                 # repos with findings (also shown when `coding` creates the container)
git-guard approve <repo>     # after checking what it found
GIT_GUARD_OFF=1 git …        # skip once
```

Other things you run on the host from `~/work` (make, npm scripts, terraform,
scripts) are not guarded: run those in the container.

Credential files for agents (API tokens, service-account JSON, kubeconfigs)
go in `~/.local/share/coding-secrets` on the host (`CODING_SECRETS_DIR`;
`coding` creates it `0700`). The container sees it read-only at `/run/secrets`
(`$AGENT_SECRETS`): outside the workspace, every repo and the vault, so it is
never committed or synced, and nothing in the container can change it. Add files
on the host with `install -m 0600 <file> ~/.local/share/coding-secrets/`; they
show up in the running container right away.

Clipboard: tmux runs with `set-clipboard external`, so only tmux copy mode and
nvim yanks reach your clipboard; programs printing OSC 52 in a tmux pane
can't replace it. Claude Code's copy still works (it runs `tmux load-buffer -w`,
or OSC 52 inside nvim's terminal). nvim's `:terminal` forwards OSC 52 from any
program running in it (nvim 0.11+, no off switch), so `cat` untrusted files in
a tmux pane, not a toggleterm. Paste in nvim
(`scripts/clip.sh --paste`) asks your terminal for its clipboard over OSC 52;
kitty and Ghostty ask you to allow each read by default.

To use a specific host Zsh config, add the following option before `coding`
in the Compose command. The file must be readable by the container user.

```bash
-v /absolute/path/to/.zshrc:/home/coder/.config/zsh/.zshrc:ro
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

```
.
├── config/         # mirrors ~/.config — symlinked by install.sh
│   ├── nvim/       #   Neovim Lua configuration
│   ├── i3/         #   i3wm window manager
│   ├── polybar/    #   status bar
│   ├── tmux/       #   tmux (pane jump bindings, visual pane styling)
│   ├── tmuxinator/ #   tmuxinator project layouts
│   ├── kitty/      #   kitty terminal
│   ├── ghostty/    #   Ghostty terminal (no longer installed by init.sh)
│   ├── dunst/      #   notification daemon
│   └── fcitx5/     #   input method (generated by scripts/fcitx5.sh, not linked)
├── home/           # mirrors ~ — symlinked by install.sh
│   ├── .zshrc      #   Zsh + Oh My Zsh
│   ├── .profile    #   shared env (PATH, NVM, GVM)
│   └── .gitconfig
├── scripts/        # tool installers + runtime helpers
│                   #   (claude-notify.sh, tmux-jump-*.sh, dunst-close-one.sh, ...)
│                   #   referenced live by absolute path — kept at repo root
├── install.sh      # symlinks config/ and home/ into place
├── init.sh         # installs tools, then runs install.sh
├── bootstrap.sh    # one-liner: apt deps + clone + init.sh
└── Dockerfile      # multi-stage build for the environment
```

## 📝 Troubleshooting

If you encounter issues during the Docker build, the `scripts/build_image.sh` script uses `--progress=plain` to show full logs. Each installation step is separated into its own `RUN` command in the `Dockerfile` for precise error tracking and better layer caching.
