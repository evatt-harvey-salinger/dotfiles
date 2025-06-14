#!/bin/bash

# Script to install local dependencies for dotfiles using Homebrew and provide guidance
# on other local setup items (like Nerd Fonts, terminal emulators).
# This script reads brew install commands from 'brew_installs.sh'.

# --- Configuration ---
# Local dotfiles directory (this script assumes it's run from within or next to your dotfiles repo)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW_INSTALLS_FILE="${DOTFILES_DIR}/brew_installs.sh"

# --- Helper Functions ---

# Displays the script's usage instructions.
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Installs local dependencies for your dotfiles environment."
    echo "Reads 'brew install' commands from '${BREW_INSTALLS_FILE}'."
    echo ""
    echo "Options:"
    echo "  --dry-run, -n    : Perform a dry run (show what would be installed without actual changes)."
    echo "  --skip-brew-install : Skip the brew installation steps (useful if you only want advice)."
    echo "  --help, -h       : Show this help message and exit."
    echo ""
    echo "Example: $0"
    echo "Example: $0 --dry-run"
    exit 1
}

# Prompts the user for confirmation for an action.
# Argument 1: The message to display to the user.
# Returns 0 for 'yes', 1 for 'no'.
confirm_action() {
    local prompt_message="$1"
    echo -n "$prompt_message (y/N): "
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        return 0
    else
        return 1
    fi
}

# Checks if Homebrew is installed. If not, prompts the user to install it.
check_homebrew() {
    if command -v brew &>/dev/null; then
        echo "✅ Homebrew is already installed."
        return 0
    else
        echo "❌ Homebrew is not installed."
        echo "Homebrew is required for some installations."
        if confirm_action "Do you want to install Homebrew now? (Requires internet access and sudo for initial setup)"; then
            echo "Installing Homebrew..."
            echo "You will be prompted for your password."
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                echo "✅ Homebrew installed successfully."
                # Add brew to PATH for current session
                if [ -f "/opt/homebrew/bin/brew" ]; then # For Apple Silicon
                    export PATH="/opt/homebrew/bin:$PATH"
                elif [ -f "/usr/local/bin/brew" ]; then # For Intel Mac
                    export PATH="/usr/local/bin:$PATH"
                fi
                return 0
            else
                echo "❌ Failed to install Homebrew. Please install it manually from https://brew.sh/ or resolve the issue."
                return 1
            FIfI
        else
            echo "Skipping Homebrew installation. Some dependencies may not be installed."
            return 1
        fi
    fi
}

# --- Main Logic ---

DRY_RUN=false
SKIP_BREW_INSTALL=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            echo "ℹ️ Dry run mode enabled. No commands will be executed."
            ;;
        --skip-brew-install)
            SKIP_BREW_INSTALL=true
            echo "ℹ️ Skipping Homebrew installation steps."
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "❌ Error: Unknown option '$1'"
            usage
            ;;
    esac
    shift # Move to the next argument
done

echo "--- Local Dotfiles Dependencies Installation ---"
echo "Dotfiles Directory: $DOTFILES_DIR"
echo "----------------------------------------------"

# --- 1. Homebrew Check and Installation ---
if [ "$SKIP_BREW_INSTALL" = false ]; then
    echo ""
    echo "--- Checking Homebrew Installation ---"
    if ! check_homebrew; then
        echo "Homebrew is not ready. Skipping 'brew install' commands."
        SKIP_BREW_INSTALL=true # Ensure brew steps are skipped if check_homebrew failed
    fi
fi


# --- 2. Execute Brew Installs from brew_installs.sh ---
if [ "$SKIP_BREW_INSTALL" = false ]; then
    echo ""
    echo "--- Processing 'brew_installs.sh' ---"
    if [ -f "$BREW_INSTALLS_FILE" ]; then
        echo "Reading brew commands from: $BREW_INSTALLS_FILE"
        IFS=$'\n' # Set Internal Field Separator to newline to read line by line
        BREW_COMMANDS=($(grep -E '^\s*brew install' "$BREW_INSTALLS_FILE" | sed 's/^\s*//'))
        unset IFS

        if [ ${#BREW_COMMANDS[@]} -eq 0 ]; then
            echo "No 'brew install' commands found in '$BREW_INSTALLS_FILE'."
        else
            echo "Found ${#BREW_COMMANDS[@]} 'brew install' commands."
            if ! confirm_action "Do you want to run these brew install commands?"; then
                echo "Skipping 'brew install' commands."
            else
                for cmd in "${BREW_COMMANDS[@]}"; do
                    echo ""
                    echo "Executing: $cmd"
                    if [ "$DRY_RUN" = true ]; then
                        echo "  (Dry run: Would execute '$cmd')"
                    else
                        if ! eval "$cmd"; then # Use eval to execute the full command string
                            echo "❌ ERROR: Command failed: '$cmd'. Please check the error above."
                        else
                            echo "✅ Command completed successfully."
                        fi
                    fi
                done
            fi
        fi
    else
        echo "❌ WARNING: '${BREW_INSTALLS_FILE}' not found. Skipping brew installations."
    fi
fi


# --- 3. Additional Local Dependencies and Advice (from TODO.md) ---
echo ""
echo "--- Additional Local Setup and Reminders ---"
echo "Based on your 'TODO.md' and common dotfile setups, here are some manual steps or checks:"

echo ""
echo "💡 Nerd Fonts Installation:"
echo "   - For proper display in Neovim and terminal emulators (like WezTerm, Alacritty, Kitty),"
echo "     you need to install a Nerd Font on your *local* system."
echo "   - Download from: https://www.nerdfonts.com/font-downloads"
echo "   - Common choices: MesloLGS Nerd Font (as seen in your wezterm.lua), FiraCode Nerd Font."
echo "   - After installing, configure your terminal emulator to use the new font."

echo ""
echo "💡 Terminal Emulator Setup (WezTerm/Kitty):"
echo "   - Your wezterm.lua suggests you use WezTerm."
echo "   - Ensure you have WezTerm or Kitty installed locally for optimal Neovim image support."
echo "   - WezTerm: https://wezterm.org/install.html"
echo "   - Kitty:   https://sw.kovidgoyal.net/kitty/binary/"
echo "   - Your 'wezterm.lua' config file has been set up via 'install.sh' if you ran it."

echo ""
echo "💡 Molten-nvim Notebook Setup:"
echo "   - Your TODO.md mentions 'Finish Notebook setups for molten-vim'."
echo "   - Refer to the official molten-nvim documentation for specific steps:"
echo "     https://github.com/benlubas/molten-nvim/blob/main/docs/Notebook-Setup.md"
echo "   - This typically involves installing language kernels (e.g., Jupyter) and other prerequisites."

echo ""
echo "💡 Image.nvim Specific Dependencies (if not covered by brew installs):"
echo "   - Your 'luarocks_and_magik_installation_for_image_nvim.md' mentions:"
echo "     - 'libmagickwand-dev' (typically `apt install` on Linux, but `imagemagick` via brew on macOS includes it)."
echo "     - 'luajit' (can be `brew install luajit`)"
echo "     - 'luarocks' (can be `brew install luarocks`)"
echo "     - 'luarocks install magick' (this installs a Lua package, not a system package, and usually needs `sudo`)"
echo "   - Ensure these are available if your `brew_installs.sh` doesn't cover them or if you're on Linux."
echo "   - If you're on macOS and your `brew_installs.sh` already includes `luarocks`, you might need to manually run `sudo luarocks install magick`."

echo ""
echo "💡 .bashrc or .zshrc configurations:"
echo "   - Your TODO.md mentions 'Add .bashrc configs'."
echo "   - If you have a `.bashrc` or `.zshrc` file in your dotfiles, remember to symlink it"
echo "     using your 'install.sh' script, and then source it in your shell (e.g., `source ~/.bashrc`)"
echo "     or restart your terminal."

echo "----------------------------------------------"
echo "Local dependency setup process complete!"
echo "Please review the advice above for further manual steps."
echo "----------------------------------------------"

