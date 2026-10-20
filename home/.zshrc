# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source $HOME/.profile

export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git z zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

alias vim='nvim'
alias tmuxi='tmuxinator'
alias cc='claude'
alias oc='opencode --auto'
alias lzg='lazygit'
alias lzd='lazydocker'
alias genpass='( tr -dc "A-Za-z0-9" < /dev/urandom | head -c 14; tr -dc "!@#$%" < /dev/urandom | head -c 2 ) | fold -w1 | shuf | tr -d "\n" | xclip -selection clipboard'


# Preferred editor for local and remote sessions
export EDITOR='nvim'
export VISUAL='nvim'

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias vim=nvim

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"



# gvm + deno env are sourced once via ~/.profile (sourced above) — no repeat here.


# ssh-agent via keychain: one shared agent per boot. First shell after boot
# prompts for each key passphrase once; every later shell (and tmux pane) reuses
# the same agent with no prompt. Push the socket into tmux so all panes agree.
if command -v keychain >/dev/null 2>&1; then
  eval "$(keychain --eval --quiet --agents ssh \
    aioz-ipfs-prod aioz-monitor aioz-storage-prod cdn-demo demo-cicd dvault \
    github gitlab-stagging-cicd hub internal_gitlab stag stream-prod \
    tailscail transcribe)"
  [[ -n $TMUX && -n $SSH_AUTH_SOCK ]] && \
    tmux set-environment -g SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null
fi

# Keep DISPLAY / SSH_AUTH_SOCK fresh inside tmux. A pane whose shell started
# before the X session (re)attached otherwise keeps a stale/empty DISPLAY, which
# breaks X tools like xprop and xclip ("unable to open display ''"). Re-sync from
# tmux's session environment (fed by update-environment on attach) each prompt.
if [[ -n $TMUX ]]; then
  _tmux_sync_env() {
    local var line
    for var in DISPLAY SSH_AUTH_SOCK; do
      line=$(tmux show-environment "$var" 2>/dev/null)
      [[ $line == "$var="* ]] && export "$line"
    done
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _tmux_sync_env
fi

# Added by Antigravity CLI installer
export PATH="/home/tuan/.local/bin:$HOME/go/bin:$PATH"

# opencode
export PATH=/home/tuan/.opencode/bin:$PATH

# dedup history (added by claude)
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS

# pnpm
export PNPM_HOME="/home/tuan/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Config drift check for ~/work/config (see update.sh). Prints one line before
# the first prompt when this machine has unpushed/uncommitted config edits or
# is behind origin. Remote refs are refreshed by a background fetch at most
# every 6h, so startup never waits on the network. Runs from precmd, not
# inline, so it doesn't trip the p10k instant-prompt console-output warning.
alias cfgup='~/work/config/update.sh'
_config_drift_check() {
  add-zsh-hook -d precmd _config_drift_check
  local repo=~/work/config stamp=${XDG_CACHE_HOME:-$HOME/.cache}/config-drift-fetch
  [[ -d $repo/.git ]] || return
  local -a stale=($stamp(N.mh+6))
  if [[ ! -e $stamp ]] || (( $#stale )); then
    : >| $stamp
    (GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes' \
      git -C $repo fetch -q &>/dev/null &)
  fi
  local -a msg
  [[ -n $(git -C $repo status --porcelain 2>/dev/null) ]] && msg+=("uncommitted edits")
  local ahead behind
  read -r ahead behind < <(git -C $repo rev-list --left-right --count HEAD...@{u} 2>/dev/null)
  (( ahead > 0 )) && msg+=("$ahead unpushed")
  (( behind > 0 )) && msg+=("$behind behind origin, run cfgup")
  (( $#msg )) && print -P "%F{yellow}config:%f ${(j:, :)msg}"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _config_drift_check
