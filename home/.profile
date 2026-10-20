# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
	# include .bashrc if it exists
	if [ -f "$HOME/.bashrc" ]; then
		. "$HOME/.bashrc"
	fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
	PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
	PATH="$HOME/.local/bin:$PATH"
fi

alias vim='nvim'
alias tmuxi='tmuxinator'
alias cc='claude'

export SHELL=/bin/zsh
export EDITOR=nvim

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

export BROWSER=/usr/bin/firefox

export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm: sourcing nvm.sh eagerly costs ~700ms + a per-cd hook. But
# node/npm/npx must resolve via plain PATH lookup too, not just inside this
# shell: non-interactive subprocesses (Claude Code hooks run via `/bin/sh -c`,
# cron, etc.) never trigger a shell function, so a function-only shim leaves
# `node: not found` for anything spawned outside an interactive shell. Instead,
# cheaply resolve the default version's bin dir (no nvm.sh sourcing) and put it
# on PATH unconditionally; only `nvm` itself (not a real binary) stays lazy.
_nvm_default_bin() {
	local dir="$NVM_DIR/versions/node" want match
	[ -d "$dir" ] || return 1
	want=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
	[ -n "$want" ] && match=$(command ls -1 "$dir" 2>/dev/null | grep -E "^v${want#v}(\.|$)" | sort -V | tail -1)
	[ -z "$match" ] && match=$(command ls -1 "$dir" 2>/dev/null | sort -V | tail -1)
	[ -n "$match" ] && printf '%s/%s/bin' "$dir" "$match"
}
_nvm_bin=$(_nvm_default_bin)
[ -n "$_nvm_bin" ] && PATH="$_nvm_bin:$PATH"
unset _nvm_bin

_nvm_lazy() {
	unset -f nvm _nvm_lazy 2>/dev/null
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { _nvm_lazy; nvm "$@"; }

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

export PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
conda() {
	unset -f conda
	[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ] && . "$HOME/miniconda3/etc/profile.d/conda.sh"
	conda "$@"
}
# __conda_setup="$('/home/tuan/miniconda3/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
# if [ $? -eq 0 ]; then
# 	eval "$__conda_setup"
# else
# 	if [ -f "/home/tuan/miniconda3/etc/profile.d/conda.sh" ]; then
# 		. "/home/tuan/miniconda3/etc/profile.d/conda.sh"
# 	else
# 		export PATH="/home/tuan/miniconda3/bin:$PATH"
# 	fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# GVM
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
. "/home/tuan/.deno/env"

# Added by Antigravity CLI installer
export PATH="/home/tuan/.local/bin:$PATH"
