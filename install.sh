#!/bin/bash

# Script to symlink dotfiles from this repository to their correct locations.
# Compatible with older Bash versions (avoids associative arrays).

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration Definitions ---
# Using indexed arrays for compatibility
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

# Define your configurations here:
add_config "opencode" "opencode" ".config/opencode"
# add_config "<name>" "<path_in_dotfiles_repo>" "<target_path_for_symlink_in_home>"
add_config "nvim" "nvim" ".config/nvim"
add_config "tmux-conf" "tmux/tmux.conf" ".tmux.conf" # Tmux configuration file
add_config "tmux-dir" ".tmux" ".tmux"         # Tmux directory (for plugins, etc.)
add_config "alacritty" "alacritty" ".config/alacritty" # Assumes ~/dotfiles/alacritty directory

# Example for zshrc (uncomment and ensure ~/dotfiles/zshrc exists)
# add_config "zshrc" "zshrc" ".zshrc"

# --- End of Configuration Definitions ---

ALL_CONFIGS=("${config_names[@]}") # These are the individual, installable units

# --- Helper Functions ---
usage() {
    echo "Dotfiles Installation Script"
    echo "----------------------------"
    echo "Usage: $0 [all | <config_name1> <config_name2> ... | tmux | --help]"
    echo ""
    echo "Commands:"
    echo "  all                   Install all available configurations."
    echo "  <config_name>         Install one or more specific configurations (see below)."
    echo "  tmux                  Install both 'tmux-conf' and 'tmux-dir'."
    echo "  --help, -h            Show this help message."
    echo ""
    echo "Available individual configurations:"
    if [ ${#ALL_CONFIGS[@]} -eq 0 ]; then
        echo "  No configurations defined in the script."
    else
        for i in "${!config_names[@]}"; do
            local name="${config_names[$i]}"
            # To display relative paths for source for better readability in help
            local src_display="${config_sources[$i]#$DOTFILES_DIR/}"
            local tgt_display="${config_targets[$i]#$HOME/}"
            echo "  - $name  (Source: ./$src_display, Target: ~/$tgt_display)"
        done
        echo ""
        echo "  Note: Using 'tmux' as an argument is a shortcut to install both 'tmux-conf' and 'tmux-dir'."
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

# Helper function to add a configuration name to the processing list if it's not already there
add_to_process_list_if_new() {
    local cfg_to_add="$1"
    local is_present=false
    for existing_cfg in "${configs_to_process_names[@]}"; do
        if [ "$existing_cfg" == "$cfg_to_add" ]; then
            is_present=true
            break
        fi
    done
    if [ "$is_present" = false ]; then
        configs_to_process_names+=("$cfg_to_add")
    fi
}


# --- Main Logic ---
mkdir -p "$HOME/.config" # Ensure .config exists, common parent for many configs
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
    # When 'all' is specified, add all defined individual configurations
    for cfg_name in "${ALL_CONFIGS[@]}"; do
        add_to_process_list_if_new "$cfg_name"
    done
    echo "🚀 Installing all defined configurations..."
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
else
    for arg_config_name in "$@"; do
        if [ "$arg_config_name" == "tmux" ]; then
            echo "ℹ️ 'tmux' argument found. Adding 'tmux-conf' and 'tmux-dir' to installation list."
            add_to_process_list_if_new "tmux-conf"
            add_to_process_list_if_new "tmux-dir"
        else
            is_known_individual_config=false
            for known_cfg_name in "${ALL_CONFIGS[@]}"; do # ALL_CONFIGS contains individual units like tmux-conf, tmux-dir
                if [ "$arg_config_name" == "$known_cfg_name" ]; then
                    add_to_process_list_if_new "$arg_config_name"
                    is_known_individual_config=true
                    break
                fi
            done
            if [ "$is_known_individual_config" = false ]; then
                # This warning will also catch "tmux" if it's not handled above,
                # but since it is, this branch is for truly unknown configs.
                echo "❓ WARNING: Unknown configuration name '$arg_config_name'. Skipping."
            fi
        fi
    done

    if [ ${#configs_to_process_names[@]} -eq 0 ]; then
        # This case would be hit if only unknown arguments were provided.
        echo "No valid configurations selected to install from your input."
        usage # Show usage if no valid configs ended up in the list
    fi
    echo "🚀 Installing selected configurations: ${configs_to_process_names[*]}"
fi

echo "----------------------------------------"
successful_installs=0
failed_installs=0

# Ensure configs_to_process_names contains unique entries before processing
# Though add_to_process_list_if_new should handle this, an explicit unique step can be added if needed.
# For now, the symlink check for existing correct links handles idempotency.

for config_name_to_install in "${configs_to_process_names[@]}"; do
    echo "Processing '$config_name_to_install'..."
    current_source=""
    current_target=""
    found_config_details=false
    for i in "${!config_names[@]}"; do # Iterate through the defined config_names (tmux-conf, tmux-dir, etc.)
        if [ "${config_names[$i]}" == "$config_name_to_install" ]; then
            current_source="${config_sources[$i]}"
            current_target="${config_targets[$i]}"
            found_config_details=true
            break
        fi
    done

    if [ "$found_config_details" = false ]; then
        # This should ideally not happen if configs_to_process_names only contains valid names.
        echo "❌ ERROR: Could not find details for '$config_name_to_install'. This is unexpected. Skipping."
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
    # Use flags to give advice once per category, even if multiple related configs were installed
    gave_nvim_advice=false
    gave_tmux_advice=false
    gave_alacritty_advice=false

    # Check which types of configurations were successfully processed
    # This requires checking against the original config_names for categorization
    temp_processed_names_for_advice=() # Store unique names that were actually processed for advice
    
    # Build a list of successfully processed config types for advice
    # This is a bit tricky as we don't explicitly store successful names, only counts.
    # We'll iterate configs_to_process_names and assume success if successful_installs > 0
    # and the config type matches. A more robust solution would be to track successful names.

    for name_processed in "${configs_to_process_names[@]}"; do
        # This loop is to determine which *types* of advice to give
        # based on what was in the processing list.
        if [[ "$name_processed" == "nvim" && "$gave_nvim_advice" = false ]]; then
            echo "  - For Neovim: Open 'nvim' and run your plugin manager's install/sync command (e.g., :Lazy sync if you use lazy.nvim)."
            gave_nvim_advice=true
        elif [[ ( "$name_processed" == "tmux-conf" || "$name_processed" == "tmux-dir" ) && "$gave_tmux_advice" = false ]]; then
            echo "  - For Tmux: If you use a plugin manager like TPM (expected to be in ~/.tmux/plugins/tpm), start tmux and press 'Prefix + I' to install plugins. Ensure your ~/.tmux.conf is set up to source these plugins."
            gave_tmux_advice=true
        elif [[ "$name_processed" == "alacritty" && "$gave_alacritty_advice" = false ]]; then
            echo "  - For Alacritty: Ensure Alacritty terminal emulator is installed on your system. Changes should take effect on the next launch."
            gave_alacritty_advice=true
        fi
    done
    
    echo "  - Review any error messages above if installs failed."
    echo "  - Ensure any necessary applications (Neovim, Tmux, Alacritty, etc.) are installed on this system."
fi