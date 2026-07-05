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
alias lzg='lazygit'
alias genpass="( < /dev/urandom tr -dc 'A-Za-z0-9' | head -c 14; < /dev/urandom tr -dc '!@#$%' | head -c 2 ) | fold -w1 | shuf | tr -d '\n' | xclip -selection clipboard"


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



[[ -s "/home/tuan/.gvm/scripts/gvm" ]] && source "/home/tuan/.gvm/scripts/gvm"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
. "/home/tuan/.deno/env"


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
export PATH="/home/tuan/.local/bin:$PATH"
