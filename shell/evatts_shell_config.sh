# Master shell configuration file
# Sources all personal shell scripts

# Use DOTFILES_SHELL_DIR if set, otherwise try to auto-detect
if [ -z "$DOTFILES_SHELL_DIR" ]; then
  # Try to detect the directory of this file
  # Works for Bash and Zsh
  if [ -n "${BASH_SOURCE[0]}" ]; then
    DOTFILES_SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  elif [ -n "${(%):-%N}" ]; then
    DOTFILES_SHELL_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
  else
    echo "Could not determine DOTFILES_SHELL_DIR"
    return 1
  fi
fi

source "$DOTFILES_SHELL_DIR/vi_mode.sh"
source "$DOTFILES_SHELL_DIR/aliases.sh"
source "$DOTFILES_SHELL_DIR/git.sh"
