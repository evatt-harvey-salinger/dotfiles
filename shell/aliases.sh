# Reload shell configuration
reload() {
  if [ -n "$BASH_VERSION" ]; then
    source ~/.bashrc
    echo "Bash configuration reloaded."
  elif [ -n "$ZSH_VERSION" ]; then
    source ~/.zshrc
    echo "Zsh configuration reloaded."
  else
    echo "Unsupported shell."
  fi
}
alias src='reload'

# File listing aliases
alias ll='ls -alF'
alias lt='ls -lrt'
alias la='ls -A'
alias l='ls -CF'

# Cursor alias
alias ced='cursor'

# Tmux session management aliases
alias tmuxn='tmux new -s'
alias tmuxa='tmux attach -t'
alias tmuxl='tmux list-sessions'
alias tmuxk='tmux kill-session -t'

# Python virtual environment aliases
alias va='source ./.venv/bin/activate'
alias vd='deactivate'

# Directory tree listing
alias t='tree -L 1'

# Custom command alias
alias oc='opencode'

# SSH shortcuts
alias ssh-d="ssh evatt_harvey-salinger@A1014"
alias ssh-g="ssh evatt@gamer"
