# Set vi mode for both shells
set -o vi

# Detect terminal support for cursor shape (optional, but recommended)
function set_cursor_shape() {
  # $1: shape code (2=block, 5=bar)
  # Only send if $TERM supports it
  case "$TERM" in
    xterm*|alacritty|screen*|tmux*|rxvt*|foot|konsole|gnome-terminal|iTerm.app)
      echo -ne "\e[${1} q"
      ;;
    *)
      # Terminal may not support cursor shape changes
      ;;
  esac
}

if [ -n "$ZSH_VERSION" ]; then
  # Zsh: dynamic cursor shape on mode change
  function zle-keymap-select() {
    case $KEYMAP in
      vicmd) set_cursor_shape 2 ;; # Block cursor
      main|viins) set_cursor_shape 5 ;; # Bar cursor
    esac
  }
  zle -N zle-keymap-select
  # Set initial cursor shape
  set_cursor_shape 5
elif [ -n "$BASH_VERSION" ]; then
  # Bash: set vi mode, set block cursor at startup
  set_cursor_shape 2
  # Bash can't dynamically change cursor shape on mode switch
fi
