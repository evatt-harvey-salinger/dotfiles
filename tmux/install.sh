#!/bin/bash

# Script to symlink Tmux dotfiles from this repository to their correct locations.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration Definitions ---
config_names=()
config_sources=()
config_targets=()

# Helper function to add a configuration
add_config() {
    local name="$1"
    local source_suffix="$2"
    local target_suffix="$3"
    config_names+=("$name")
    config_sources+=("$DOTFILES_DIR/$source_suffix")
    config_targets+=("$HOME/$target_suffix")
}

# Define Tmux configurations here:

# Function to get Tmux version
get_tmux_version() {
    if command -v tmux &> /dev/null; then
        tmux -V | grep -oE '[0-9]+\.[0-9]+'
    else
        echo "0.0" # Return a low version if tmux is not found
    fi
}

# Determine Tmux configuration target based on version
TMUX_VERSION=$(get_tmux_version)
TMUX_CONFIG_TARGET=".config/tmux/tmux.conf"

if (( $(echo "$TMUX_VERSION < 3.1" | bc -l) )); then
    echo "Detected Tmux version $TMUX_VERSION, which is less than 3.1. Symlinking to ~/$TMUX_CONFIG_TARGET and ~/.config/tmux/tmux.conf"
    TMUX_CONFIG_TARGET=".tmux.conf"
    add_config "tmux-conf-legacy-path" "tmux.conf" "$TMUX_CONFIG_TARGET" # Tmux configuration file for older versions
    add_config "tmux-conf-config-path" "tmux.conf" ".config/tmux/tmux.conf" # Tmux configuration file for reload command
else
    echo "Detected Tmux version $TMUX_VERSION, which is 3.1 or higher. Symlinking to ~/.config/tmux/tmux.conf"
    add_config "tmux-conf" "tmux.conf" "$TMUX_CONFIG_TARGET" # Tmux configuration file
fi

# --- Helper Functions ---
create_symlink() {
    local source_path="$1"
    local target_path="$2"
    local config_name="$3"

    if [ ! -e "$source_path" ]; then
        echo "❌ ERROR: Source for '$config_name' configuration not found: $source_path"
        return 1
    fi

    local target_parent_dir
    target_parent_dir=$(dirname "$target_path")
    if [ ! -d "$target_parent_dir" ]; then
        echo "🔧 Creating parent directory for target: $target_parent_dir"
        mkdir -p "$target_parent_dir"
    fi

    if [ -L "$target_path" ]; then
        local current_link_target
        current_link_target=$(readlink "$target_path")
        if [ "$current_link_target" == "$source_path" ]; then
            echo "✔ Symlink for '$config_name' already correct: $target_path -> $source_path"
            return 0
        else
            echo "⚠ Symlink for '$config_name' exists but points to '$current_link_target'. Relinking to '$source_path'."
            rm "$target_path"
        fi
    elif [ -e "$target_path" ]; then
        local backup_path="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
        echo "⚠ '$target_path' already exists and is not a symlink."
        echo "  Backing up to: $backup_path"
        mv "$target_path" "$backup_path"
    fi

    ln -sf "$source_path" "$target_path"
    if [ $? -eq 0 ]; then
        echo "✅ Symlinked '$config_name': $target_path -> $source_path"
        return 0
    else
        echo "❌ ERROR: Failed to create symlink for '$config_name': $target_path"
        return 1
    fi
}

# --- Main Logic ---
echo "🚀 Installing Tmux configurations..."

successful_installs=0
failed_installs=0

for i in "${!config_names[@]}"; do
    name="${config_names[$i]}"
    source="${config_sources[$i]}"
    target="${config_targets[$i]}"

    echo "Processing '$name'..."
    if create_symlink "$source" "$target" "$name"; then
        successful_installs=$((successful_installs + 1))
    else
        failed_installs=$((failed_installs + 1))
    fi
    echo "---"
done

echo "----------------------------------------"
echo "✅ Tmux Installation Process Complete!"
echo "Summary:"
echo "  Successfully linked: $successful_installs configuration(s)."
if [ "$failed_installs" -gt 0 ]; then
    echo "  Failed/Skipped links: $failed_installs configuration(s) (see error messages above)."
fi
echo "----------------------------------------"

# --- TPM Installation ---
TPM_PATH="$HOME/.config/tmux/tpm"

install_tpm() {
    echo "Checking for Tmux Plugin Manager (TPM)..."
    if [ -d "$TPM_PATH" ]; then
        echo "✔ TPM already installed at $TPM_PATH."
    else
        echo "🔧 Installing TPM to $TPM_PATH..."
        mkdir -p "$(dirname "$TPM_PATH")"
        if git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"; then
            echo "✅ TPM installed successfully."
        else
            echo "❌ ERROR: Failed to clone TPM. Please check your internet connection or git setup."
            return 1
        fi
    fi
    return 0
}

# --- Main Logic ---
echo "🚀 Installing Tmux configurations..."

successful_installs=0
failed_installs=0

# Install TPM first
if install_tpm; then
    echo "---"
else
    failed_installs=$((failed_installs + 1))
    echo "TPM installation failed, proceeding with other configurations but plugins might not load."
    echo "---"
fi

for i in "${!config_names[@]}"; do
    name="${config_names[$i]}"
    source="${config_sources[$i]}"
    target="${config_targets[$i]}"

    echo "Processing '$name'..."
    if create_symlink "$source" "$target" "$name"; then
        successful_installs=$((successful_installs + 1))
    else
        failed_installs=$((failed_installs + 1))
    fi
    echo "---"
done

echo "----------------------------------------"
echo "✅ Tmux Installation Process Complete!"
echo "Summary:"
echo "  Successfully linked: $successful_installs configuration(s)."
if [ "$failed_installs" -gt 0 ]; then
    echo "  Failed/Skipped links: $failed_installs configuration(s) (see error messages above)."
fi

if [ "$successful_installs" -gt 0 ]; then
    echo ""
    echo "💡 Next Steps & Reminders:"
    echo "  - For Tmux: Start tmux and press 'Prefix + I' to install plugins."
    echo "  - Review any error messages above if installs failed."
fi

