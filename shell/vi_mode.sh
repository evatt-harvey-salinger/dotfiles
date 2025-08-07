# Set vi mode for both shells
set -o vi

# This code detects the shell and sets the cursor style accordingly
if [ -n "$BASH_VERSION" ]; then
  # === Bash Specific Configuration ===

  # This sets the cursor to a block by default (for normal mode)
  echo -ne '\e[2 q'

  # This function changes the cursor to a vertical bar when entering insert mode
  function set_insert_mode_cursor() {
      echo -ne '\e[5 q'
      set -o vi
  }

  # This function changes the cursor to a block when entering normal mode
  function set_normal_mode_cursor() {
      echo -ne '\e[2 q'
      set -o vi
  }

  # Bind the functions to the vi mode switches
  bind -x '"\C-i": "set_insert_mode_cursor"' # Ctrl+I
  bind -x '"\e": "set_normal_mode_cursor"'   # Escape

elif [ -n "$ZSH_VERSION" ]; then
  # === Zsh Specific Configuration ===

  # This hook changes the cursor when the keymap is selected
  function zle-keymap-select() {
    case $KEYMAP in
      vicmd) echo -ne '\e[2 q';; # Normal mode (block cursor)
      main|viins) echo -ne '\e[5 q';; # Insert mode (vertical bar cursor)
    esac
  }
  zle -N zle-keymap-select

  # Start with the insert mode cursor
  echo -ne '\e[5 q'
fi
