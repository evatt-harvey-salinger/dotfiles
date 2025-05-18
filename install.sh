#!/bin/bash

# Script to symlink dotfiles from this repository to their correct locations.
#
# Usage:
#   ./install.sh all                      (Installs all defined configurations)
#   ./install.sh nvim tmux                (Installs only nvim and tmux)
#   ./install.sh                          (Shows usage)
#   ./install.sh --help                   (Shows usage)

# Get the absolute path to the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration Definitions ---
# Define your configurations here.
# For each configuration, specify its 'name', its 'source' path relative to $DOTFILES_DIR,
# and its 'target' symlink path in the $HOME directory.

# Associative arrays for sources and targets
# Format: config_sources["<name>"]="$DOTFILES_DIR/<path_in_dotfiles_repo>"
#         config_targets["<name>"]="$HOME/<target_path_for_symlink>"
declare -A config_sources
declare -A config_targets

# Neovim Configuration
config_sources["nvim"]="$DOTFILES_DIR/nvim"
config_targets["nvim"]="$HOME/.config/nvim"

# Tmux Configuration
config_sources["tmux"]="$DOTFILES_DIR/tmux.conf"
config_targets["tmux"]="$HOME/.tmux.conf"

# Zsh Configuration (Example - uncomment and adjust if you have it)
# config_sources["zshrc"]="$DOTFILES_DIR/zshrc"
# config_targets["zshrc"]="$HOME/.zshrc"

# Git Configuration (Example - uncomment and adjust if you have it)
# config_sources["gitconfig"]="$DOTFILES_DIR/gitconfig"
# config_targets["gitconfig"]="$HOME/.gitconfig"

# Add more configurations as needed following the pattern above.

# --- End of Configuration Definitions ---

# Get all defined configuration names (keys of the associative array)
ALL_CONFIGS=("${!config_sources[@]}")

# --- Helper Functions ---

usage() {
    echo "Dotfiles Installation Script"
    echo "----------------------------"
    echo "Usage: $0 [all | <config_name1> <config_name2> ... | --help]"
    echo ""
    echo "Commands:"
    echo "  all                   Install all available configurations."
    echo "  <config_name>         Install one or more specific configurations."
    echo "  --help, -h            Show this help message."
    echo ""
    echo "Available configurations:"
    if [ ${#ALL_CONFIGS[@]} -eq 0 ]; then
        echo "  No configurations defined in the script."
    else
        for cfg in "${ALL_CONFIGS[@]}"; do
            echo "  - $cfg  (Source: ${config_sources[$cfg]}, Target: ${config_targets[$cfg]})"
        done
    fi
    exit 1
}

# Function to create a symlink, backing up existing file/dir if it's not already a symlink
create_symlink() {
    local source_path="$1"
    local target_path="$2"
    local config_name="$3" # For logging purposes

    # Check if the source file/directory actually exists in the dotfiles repo
    if [ ! -e "$source_path" ]; then
        echo "❌ ERROR: Source for '$config_name' configuration not found: $source_path"
        return 1 # Failure
    fi

    # Ensure the parent directory of the target link exists
    local target_parent_dir
    target_parent_dir=$(dirname "$target_path")
    if [ ! -d "$target_parent_dir" ]; then
        echo "🔧 Creating parent directory for target: $target_parent_dir"
        mkdir -p "$target_parent_dir"
    fi

    # Check if the target is already a symlink
    if [ -L "$target_path" ]; then
        local current_link_target
        current_link_target=$(readlink "$target_path")
        if [ "$current_link_target" == "$source_path" ]; then
            echo "✔ Symlink for '$config_name' already correct: $target_path -> $source_path"
            return 0 # Success
        else
            echo "⚠ Symlink for '$config_name' exists but points to '$current_link_target'. Relinking to '$source_path'."
            # Remove the old symlink before creating a new one
            rm "$target_path"
        fi
    # Check if the target exists and is not a symlink (it's a regular file or directory)
    elif [ -e "$target_path" ]; then
        local backup_path="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
        echo "⚠ '$target_path' already exists and is not a symlink."
        echo "  Backing up to: $backup_path"
        mv "$target_path" "$backup_path"
    fi

    # Create the symlink
    ln -sf "$source_path" "$target_path"
    if [ $? -eq 0 ]; then
        echo "✅ Symlinked '$config_name': $target_path -> $source_path"
        return 0 # Success
    else
        echo "❌ ERROR: Failed to create symlink for '$config_name': $target_path"
        return 1 # Failure
    fi
}

# --- Main Logic ---

# Ensure $HOME/.config directory exists, as many tools place configs there
mkdir -p "$HOME/.config"

configs_to_process=()

if [ $# -eq 0 ]; then
    echo "No specific configurations requested."
    usage
fi

if [ "$1" == "all" ]; then
    if [ ${#ALL_CONFIGS[@]} -eq 0 ]; then
        echo "No configurations defined. Nothing to install."
        exit 0
    fi
    configs_to_process=("${ALL_CONFIGS[@]}")
    echo "🚀 Installing all defined configurations..."
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
else
    for arg in "$@"; do
        is_known_config=false
        for known_cfg in "${ALL_CONFIGS[@]}"; do
            if [ "$arg" == "$known_cfg" ]; then
                configs_to_process+=("$arg")
                is_known_config=true
                break
            fi
        done
        if [ "$is_known_config" = false ]; then
            echo "❓ WARNING: Unknown configuration name '$arg'. Skipping."
        fi
    done

    if [ ${#configs_to_process[@]} -eq 0 ]; then
        echo "No valid configurations selected to install from your input."
        usage
    fi
    echo "🚀 Installing selected configurations: ${configs_to_process[*]}"
fi

echo "----------------------------------------"

successful_installs=0
failed_installs=0

for config_name in "${configs_to_process[@]}"; do
    echo "Processing '$config_name'..."
    source="${config_sources[$config_name]}"
    target="${config_targets[$config_name]}"

    if create_symlink "$source" "$target" "$config_name"; then
        successful_installs=$((successful_installs + 1))
    else
        failed_installs=$((failed_installs + 1))
    fi
    echo "---" # Separator for readability
done

echo "----------------------------------------"
echo "✅ Installation Process Complete!"
echo "Summary:"
echo "  Successfully linked: $successful_installs configuration(s)."
if [ "$failed_installs" -gt 0 ]; then
    echo "  Failed/Skipped links: $failed_installs configuration(s) (see error messages above)."
fi
echo "----------------------------------------"

# Provide next steps based on what was installed
if [ "$successful_installs" -gt 0 ]; then
    echo ""
    echo "💡 Next Steps & Reminders:"
    for config_name in "${configs_to_process[@]}"; do
        if [ "$config_name" == "nvim" ]; then
            echo "  - For Neovim: Open 'nvim' and run your plugin manager's install/sync command (e.g., :Lazy sync if you use lazy.nvim)."
        elif [ "$config_name" == "tmux" ]; then
            echo "  - For Tmux: If you use a plugin manager like TPM, start tmux and press 'Prefix + I' to install plugins."
        # Add other specific post-installation messages here
        # elif [ "$config_name" == "zshrc" ]; then
        #     echo "  - For Zsh: You might need to source ~/.zshrc or open a new terminal."
        fi
    done
    echo "  - Review any error messages above if installs failed."
    echo "  - Ensure any necessary applications (Neovim, Tmux, Zsh, etc.) are installed on this system."
fi