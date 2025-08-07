#!/bin/bash

DOTFILES_SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG="$DOTFILES_SHELL_DIR/evatts_shell_config.sh"
EXPORT_LINE="export DOTFILES_SHELL_DIR=\"$DOTFILES_SHELL_DIR\""
SOURCE_LINE="source \"$SHELL_CONFIG\""

append_source_if_missing() {
  local rc_file="$1"
  if grep -Fxq "$SOURCE_LINE" "$rc_file"; then
    echo "✔ Source line already present in $rc_file"
  else
    echo "🔧 Adding export and source lines to $rc_file"
    echo -e "\n# Dotfiles shell config\n$EXPORT_LINE\n$SOURCE_LINE" >> "$rc_file"
    echo "✅ Added lines to $rc_file"
  fi
}

if [ -f "$HOME/.bashrc" ]; then
  echo "Detected .bashrc"
  append_source_if_missing "$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
  echo "Detected .zshrc"
  append_source_if_missing "$HOME/.zshrc"
else
  echo "No .bashrc or .zshrc found, creating .bashrc"
  echo -e "# Dotfiles shell config\n$EXPORT_LINE\n$SOURCE_LINE" > "$HOME/.bashrc"
  echo "✅ Created .bashrc and added lines"
fi

echo "----------------------------------------"
echo "✅ Shell configuration installation complete!"
echo "Remember to restart your shell or source your rc file to apply changes."
