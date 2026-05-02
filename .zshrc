# ~/.zshrc - modern, framework-free setup

# ---------- Basics ----------
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"

# ---------- History ----------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

# ---------- Shell behavior ----------
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# ---------- Keybindings ----------
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ---------- Completion ----------
autoload -Uz compinit

# Keep completion startup fast via cached dump.
if [[ -n ${XDG_CACHE_HOME:-} ]]; then
  _compdump_path="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
else
  _compdump_path="$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
fi
mkdir -p "${_compdump_path:h}"
compinit -d "$_compdump_path"
unset _compdump_path

# Extra community completions.
fpath=("$HOME/.zsh/plugins/zsh-completions/src" $fpath)

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true

# ---------- Colors ----------
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

# ---------- Plugins ----------
if [[ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi

if [[ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ---------- History search ----------
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ---------- Prompt ----------
autoload -Uz colors
colors

PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '

# ---------- Aliases ----------
alias ls='eza'
alias ll='eza -la --group-directories-first'
alias la='eza -a'
alias lt='eza --tree --level=2'
alias bex='cd ~/dev/bex'
alias grep='grep --color=auto'
alias clip='xclip -selection clipboard'

if command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
fi

# Git aliases
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gp='git pull --rebase'
alias gP='git push'
alias gitcount='git rev-list HEAD --count'

# ---------- Handy functions ----------
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# ---------- Rust ----------
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ---------- Optional integrations ----------
if command -v fzf >/dev/null 2>&1; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
  source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null || true
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Random tint for each new Konsole window.
# KONSOLE_TINT_APPLIED is exported so the choice survives `exec zsh` and is
# inherited by nested interactive shells — keeps the tint stable for the life
# of the Konsole session. A fresh window starts with no marker → fresh roll.
if [[ -n "$KONSOLE_DBUS_SESSION" && -n "$KONSOLE_DBUS_SERVICE" && -z "$KONSOLE_TINT_APPLIED" ]]; then
    _tints=(tint-neutral tint-red tint-green tint-blue tint-purple tint-orange)
    export KONSOLE_TINT_APPLIED="${_tints[$((RANDOM % ${#_tints[@]}+1))]}"
    qdbus6 "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" \
        org.kde.konsole.Session.setProfile "$KONSOLE_TINT_APPLIED" 2>/dev/null
    unset _tints
fi

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
