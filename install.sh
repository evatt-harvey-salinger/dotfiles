#!/bin/bash

# Script to symlink dotfiles from this repository to their correct locations.
# Compatible with older Bash versions (avoids associative arrays).

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration Definitions ---
# Using indexed arrays for compatibility
config_names=()
config_sources=() # Note: these are now simple indexed arrays
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

# Define your configurations here:
# add_config "<name>" "<path_in_dotfiles_repo>" "<target_path_for_symlink_in_home>"
add_config "nvim" "nvim" ".config/nvim"
add_config "tmux" "tmux.conf" ".tmux.conf"
add_config "alacritty" "alacritty" ".config/alacritty" # Assumes ~/dotfiles/alacritty directory

# Example for zshrc (uncomment and ensure ~/dotfiles/zshrc exists)
# add_config "zshrc" "zshrc" ".zshrc"

# --- End of Configuration Definitions ---

ALL_CONFIGS=("${config_names[@]}")

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
        for i in "${!config_names[@]}"; do
            local name="${config_names[$i]}"
            local src="${config_sources[$i]}"
            local tgt="${config_targets[$i]}"
            echo "  - $name  (Source: $src, Target: $tgt)"
        done
    fi
    exit 1
}

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
mkdir -p "$HOME/.config"
configs_to_process_names=() # Store names of configs to process

if [ $# -eq 0 ]; then
    echo "No specific configurations requested."
    usage
fi

if [ "$1" == "all" ]; then
    if [ ${#ALL_CONFIGS[@]} -eq 0 ]; then
        echo "No configurations defined. Nothing to install."
        exit 0
    fi
    configs_to_process_names=("${ALL_CONFIGS[@]}")
    echo "🚀 Installing all defined configurations..."
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
else
    for arg_config_name in "$@"; do
        is_known_config=false
        for known_cfg_name in "${ALL_CONFIGS[@]}"; do
            if [ "$arg_config_name" == "$known_cfg_name" ]; then
                configs_to_process_names+=("$arg_config_name")
                is_known_config=true
                break
            fi
        done
        if [ "$is_known_config" = false ]; then
            echo "❓ WARNING: Unknown configuration name '$arg_config_name'. Skipping."
        fi
    done

    if [ ${#configs_to_process_names[@]} -eq 0 ]; then
        echo "No valid configurations selected to install from your input."
        usage
    fi
    echo "🚀 Installing selected configurations: ${configs_to_process_names[*]}"
fi

echo "----------------------------------------"
successful_installs=0
failed_installs=0

for config_name_to_install in "${configs_to_process_names[@]}"; do
    echo "Processing '$config_name_to_install'..."
    # Find the index of this config name to get its source and target
    current_source=""
    current_target=""
    for i in "${!config_names[@]}"; do
        if [ "${config_names[$i]}" == "$config_name_to_install" ]; then
            current_source="${config_sources[$i]}"
            current_target="${config_targets[$i]}"
            break
        fi
    done

    if [ -z "$current_source" ]; then # Should not happen if logic above is correct
        echo "❌ ERROR: Could not find details for '$config_name_to_install'. Skipping."
        failed_installs=$((failed_installs + 1))
        continue
    fi

    if create_symlink "$current_source" "$current_target" "$config_name_to_install"; then
        successful_installs=$((successful_installs + 1))
    else
        failed_installs=$((failed_installs + 1))
    fi
    echo "---"
done

echo "----------------------------------------"
echo "✅ Installation Process Complete!"
echo "Summary:"
echo "  Successfully linked: $successful_installs configuration(s)."
if [ "$failed_installs" -gt 0 ]; then
    echo "  Failed/Skipped links: $failed_installs configuration(s) (see error messages above)."
fi
echo "----------------------------------------"

if [ "$successful_installs" -gt 0 ]; then
    echo ""
    echo "💡 Next Steps & Reminders:"
    for config_name_processed in "${configs_to_process_names[@]}"; do
        if [ "$config_name_processed" == "nvim" ]; then
            echo "  - For Neovim: Open 'nvim' and run your plugin manager's install/sync command (e.g., :Lazy sync if you use lazy.nvim)."
        elif [ "$config_name_processed" == "tmux" ]; then
            echo "  - For Tmux: If you use a plugin manager like TPM, start tmux and press 'Prefix + I' to install plugins."
        elif [ "$config_name_processed" == "alacritty" ]; then
            echo "  - For Alacritty: Ensure Alacritty terminal emulator is installed on your system. Changes should take effect on the next launch."
        fi
    done
    echo "  - Review any error messages above if installs failed."
    echo "  - Ensure any necessary applications (Neovim, Tmux, Alacritty, etc.) are installed on this system."
fi