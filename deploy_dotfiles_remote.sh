#!/bin/bash

# Script to deploy your entire local dotfiles repository to a remote server via SSH.
# It checks for and can install Neovim and Tmux on the remote,
# and offers to install dependencies for image.nvim.

# --- Configuration ---
# Remote server user and host (e.g., "user@your_remote_host.com")
# This variable must be provided as the first argument when running the script.
REMOTE_SERVER=""

# Local dotfiles directory (dynamically determined based on script location)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helper Functions ---

# Displays the script's usage instructions.
usage() {
  echo "Usage: $0 <remote_server_user@host> [options]"
  echo ""
  echo "Deploys your ENTIRE local dotfiles repository to a remote server."
  echo "It also checks for and can install Neovim and Tmux on the remote."
  echo ""
  echo "Arguments:"
  echo "  <remote_server_user@host> : The SSH connection string for your remote server"
  echo "                            (e.g., user@192.168.1.100 or user@myjetson.local)"
  echo ""
  echo "Options:"
  echo "  --dest <path>, -d <path> : Specify a base destination directory on the remote server"
  echo "                             (e.g., '--dest my_configs_repo' will deploy the dotfiles repo"
  echo "                             to ~/my_configs_repo/dotfiles/). If not specified, the dotfiles"
  echo "                             repository will be placed directly in ~/dotfiles/."
  echo "  --dry-run, -n            : Perform a dry run (show what would be copied/installed without actual changes)."
  echo "  --force, -f              : Force overwrite of existing files on remote without confirmation (use with caution!)."
  echo "  --help, -h               : Show this help message and exit."
  echo ""
  echo "Example: $0 user@myjetson.local"
  echo "Example: $0 user@myjetson.local --dest backup_repos"
  echo "Example: $0 user@myjetson.local --dry-run"
  exit 1
}

# Prompts the user for confirmation for an action.
# Argument 1: The message to display to the user.
# Returns 0 for 'yes', 1 for 'no'.
confirm_action() {
  local prompt_message="$1"
  if [[ "$FORCE_OVERWRITE" == "true" ]]; then
    return 0 # Auto-confirm if force flag is set
  fi

  echo -n "$prompt_message (y/N): "
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 0
  else
    return 1
  fi
}

# Checks if a package is installed on the remote server and offers to install it if not.
# Argument 1: The name of the package/command to check for (e.g., "nvim", "tmux").
# Argument 2: The command to execute on the remote to install the package (e.g., "sudo apt install -y neovim").
# Argument 3 (Optional): Alternate command to check for presence, if different from 'command -v package_name'.
# Returns 0 if installed/successfully installed, 1 otherwise.
check_and_install_remote_package() {
  local package_name="$1"
  local install_cmd="$2"
  local check_cmd="${3:-command -v $package_name}"

  echo ""
  echo "--- Checking for '$package_name' on $REMOTE_SERVER ---"

  if ssh "$REMOTE_SERVER" "$check_cmd" &>/dev/null; then
    echo "✅ '$package_name' is already installed."
    return 0
  else
    echo "❌ '$package_name' is NOT installed."
    if confirm_action "Do you want to install '$package_name' on '$REMOTE_SERVER'? (Requires sudo privileges)"; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "  (Dry run: Would execute: ssh $REMOTE_SERVER \"$install_cmd\")"
        echo "  Please run this manually on the remote to install: $install_cmd"
        return 1
      else
        echo "Attempting to install '$package_name'..."
        echo "You may be prompted for your sudo password on the remote server."
        if ssh -t "$REMOTE_SERVER" "$install_cmd"; then
          echo "✅ '$package_name' installed successfully."
          return 0
        else
          echo "❌ Failed to install '$package_name'. Check permissions/internet on remote."
          return 1
        fi
      fi
    else
      echo "Skipping installation of '$package_name'."
      return 1
    fi
  fi
}

# --- Main Logic ---

DRY_RUN=false
FORCE_OVERWRITE=false
CUSTOM_REMOTE_BASE_DIR=""

# Parse command-line arguments
if [ "$#" -eq 0 ]; then
  usage
fi

# Check for help option early
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
fi

REMOTE_SERVER="$1"
shift

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  --dest | -d)
    if [ -z "$2" ]; then
      echo "❌ Error: --dest requires a path argument."
      usage
    fi
    CUSTOM_REMOTE_BASE_DIR="$2"
    shift
    ;;
  --dry-run | -n)
    DRY_RUN=true
    echo "ℹ️ Dry run mode enabled. No files will actually be copied or installed."
    ;;
  --force | -f)
    FORCE_OVERWRITE=true
    echo "⚠️ Force overwrite mode enabled. Existing files on remote will be overwritten without prompt."
    ;;
  *)
    echo "❌ Error: Unknown option '$1'"
    usage
    ;;
  esac
  shift
done

echo "--- Dotfiles Deployment to Remote Server ---"
echo "Remote Server: $REMOTE_SERVER"
echo "Local Dotfiles Directory: $DOTFILES_DIR"
if [ -n "$CUSTOM_REMOTE_BASE_DIR" ]; then
  echo "Custom Remote Base Directory: ~/$CUSTOM_REMOTE_BASE_DIR"
fi
echo "------------------------------------------"

# Pre-flight check: SSH connectivity
echo "Checking SSH connectivity to $REMOTE_SERVER..."
if ! ssh -q "$REMOTE_SERVER" exit; then
  echo "❌ ERROR: Cannot connect to $REMOTE_SERVER via SSH. Ensure SSH is working."
  exit 1
fi
echo "✅ SSH connection successful."

# Confirm overall action
if ! confirm_action "Proceed with checking dependencies and deploying your ENTIRE dotfiles repository to '$REMOTE_SERVER'? This will overwrite existing files."; then
  echo "Deployment cancelled by user."
  exit 0
fi

# --- 1. Remote Dependency Check and Installation ---
echo ""
echo "--- Starting Remote Dependency Checks and Optional Installations ---"

NEOVIM_INSTALLED_DURING_RUN=false
TMUX_INSTALLED_DURING_RUN=false

if check_and_install_remote_package "neovim" "sudo apt update && sudo apt install -y neovim"; then
  NEOVIM_INSTALLED_DURING_RUN=true
fi

if check_and_install_remote_package "tmux" "sudo apt update && sudo apt install -y tmux"; then
  TMUX_INSTALLED_DURING_RUN=true
fi

echo ""
echo "--- Optional Dependencies for image.nvim ---"
if confirm_action "Check/install additional dependencies for Neovim's image.nvim plugin (libmagickwand-dev, luajit, luarocks, magick LuaRock)?"; then
  check_and_install_remote_package "libmagickwand-dev" "sudo apt update && sudo apt install -y libmagickwand-dev"
  check_and_install_remote_package "luajit" "sudo apt update && sudo apt install -y luajit"
  check_and_install_remote_package "luarocks" "sudo apt update && sudo apt install -y luarocks"

  echo ""
  echo "--- Checking for 'magick' LuaRock (for image.nvim) ---"
  if ssh "$REMOTE_SERVER" "luarocks show magick" &>/dev/null; then
    echo "✅ 'magick' LuaRock is already installed."
  else
    echo "❌ 'magick' LuaRock is NOT installed."
    if confirm_action "Install 'magick' LuaRock? (Requires 'luarocks' and sudo)"; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "  (Dry run: Would execute: ssh $REMOTE_SERVER \"sudo luarocks install magick\")"
        echo "  Please run this manually on the remote to install: sudo luarocks install magick"
      else
        echo "Attempting to install 'magick' LuaRock..."
        if ssh -t "$REMOTE_SERVER" "sudo luarocks install magick"; then
          echo "✅ 'magick' LuaRock installed successfully."
        else
          echo "❌ Failed to install 'magick' LuaRock. Check setup and sudo access."
        fi
      fi
    else
      echo "Skipping installation of 'magick' LuaRock."
    fi
  fi
else
  echo "Skipping checks/installations for image.nvim dependencies."
fi

# --- 2. Dotfiles Deployment ---
echo ""
echo "--- Starting Dotfiles Deployment ---"
echo "This will copy your ENTIRE local dotfiles repository to the remote server."

REMOTE_REPO_BASE_NAME="$(basename "$DOTFILES_DIR")"
if [ -n "$CUSTOM_REMOTE_BASE_DIR" ]; then
  REMOTE_FULL_TARGET_DIR="~/$CUSTOM_REMOTE_BASE_DIR/$REMOTE_REPO_BASE_NAME"
else
  REMOTE_FULL_TARGET_DIR="~/$REMOTE_REPO_BASE_NAME"
fi
REMOTE_RSYNC_TARGET="${REMOTE_SERVER}:${REMOTE_FULL_TARGET_DIR}"

echo "Local Source: $DOTFILES_DIR/"
echo "Remote Target: $REMOTE_RSYNC_TARGET/"

# Create parent directory for the dotfiles repository on the remote
REMOTE_PARENT_DIR_FOR_REPO=$(dirname "$REMOTE_FULL_TARGET_DIR")
if [[ "$REMOTE_PARENT_DIR_FOR_REPO" != "~" && "$REMOTE_PARENT_DIR_FOR_REPO" != "." ]]; then
  echo "Ensuring parent directory for dotfiles repo exists on remote: $REMOTE_PARENT_DIR_FOR_REPO"
  if ! $DRY_RUN; then
    LOCAL_RELATIVE_PARENT_DIR="${REMOTE_PARENT_DIR_FOR_REPO#\~/}"
    ssh "$REMOTE_SERVER" "mkdir -p ~/$LOCAL_RELATIVE_PARENT_DIR"
    if [ $? -ne 0 ]; then
      echo "❌ ERROR: Failed to create remote directory ~/$LOCAL_RELATIVE_PARENT_DIR. Skipping dotfiles deployment."
      exit 1
    fi
  else
    echo "  (Dry run: Would create remote directory ~/${REMOTE_PARENT_DIR_FOR_REPO#\~/})"
  fi
fi

RSYNC_OPTIONS="-avh --progress --checksum --delete-after"
if [ "$DRY_RUN" = true ]; then
  RSYNC_OPTIONS+=" --dry-run"
fi

echo "Executing rsync command for entire dotfiles directory..."
if rsync $RSYNC_OPTIONS "$DOTFILES_DIR/" "$REMOTE_RSYNC_TARGET/"; then
  echo "✅ Successfully synced entire dotfiles repository."
else
  echo "❌ ERROR: Failed to sync dotfiles repository. See output above for details."
  exit 1
fi

echo ""
echo "--- Deployment Process Complete ---"
echo "Next Steps (to be performed manually on the remote server):"

echo "Your entire local dotfiles repository has been deployed to:"
echo "  $REMOTE_FULL_TARGET_DIR/"
echo ""
echo "You will likely need to create symbolic links (symlinks) from this location"
echo "to the standard configuration locations on your remote system. For example:"
echo "  ssh $REMOTE_SERVER"
echo "  mkdir -p ~/.config"
echo "  ln -sf $REMOTE_FULL_TARGET_DIR/nvim ~/.config/nvim"
echo "  ln -sf $REMOTE_FULL_TARGET_DIR/tmux.conf ~/.tmux.conf"
echo "  ln -sf $REMOTE_FULL_TARGET_DIR/.tmux ~/.tmux"
echo ""

if [ "$NEOVIM_INSTALLED_DURING_RUN" = true ]; then
  echo "💡 Neovim was just installed. After creating the symlink, ensure you open Neovim and install plugins."
fi
echo "For Neovim configuration to take full effect (after symlinking):"
echo "   1. SSH into the remote server: ssh $REMOTE_SERVER"
echo "   2. Open Neovim: nvim"
echo "   3. Run your plugin manager's install/sync command (e.g., :Lazy sync)."

if [ "$TMUX_INSTALLED_DURING_RUN" = true ]; then
  echo "💡 Tmux was just installed. After creating the symlink, ensure you install TPM plugins."
fi
echo "For Tmux configuration to take full effect (after symlinking):"
echo "   1. Ensure TPM is cloned/installed (expected at ~/.tmux/plugins/tpm, which will be symlinked)."
echo "   2. Start tmux: tmux"
echo "   3. Inside tmux, press your prefix key (Ctrl+a by default) then 'I' (capital i) to install/sync plugins."
echo "   4. If you had an existing tmux session, kill it and restart, or source the config: tmux source-file ~/.tmux.conf"

echo ""
echo "Additional Important Notes:"
echo "  - Nerd Fonts: Install Nerd Fonts on your *local* machine for proper display."
echo "  - Manual Verification: Review script output and manually verify configurations on the remote."
echo "  - Internet Access: Ensure your Jetson has internet access for $(apt) and $(luarocks) installations."
echo "------------------------------------------"
