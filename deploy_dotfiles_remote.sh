#!/bin/bash

# Script to deploy Neovim and Tmux configurations to a remote server via SSH.

# --- Configuration ---
# Remote server user and host (e.g., "user@your_remote_host.com")
REMOTE_SERVER=""

# Local dotfiles directory (this script assumes it's run from within or next to your dotfiles repo)
# Adjust DOTFILES_DIR if your script is not in the same directory as nvim and tmux.conf
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define configurations to deploy
declare -A CONFIGS_TO_DEPLOY=(
  ["nvim"]=".config/nvim"
  ["tmux.conf"]=".tmux.conf"
  ["tmux_dir"]=".tmux" # Assuming .tmux directory for plugins etc.
)

# --- Helper Functions ---

usage() {
  echo "Usage: $0 <remote_server_user@host> [options]"
  echo ""
  echo "Deploys specified dotfiles (Neovim, Tmux) to a remote server."
  echo ""
  echo "Arguments:"
  echo "  <remote_server_user@host> : The SSH connection string for your remote server (e.g., user@192.168.1.100)"
  echo ""
  echo "Options:"
  echo "  --dry-run, -n    : Perform a dry run (show what would be copied without actually copying)."
  echo "  --force, -f      : Force overwrite of existing files on remote without confirmation (use with caution!)."
  echo "  --help, -h       : Show this help message and exit."
  echo ""
  echo "Example: $0 user@myremoteserver.com"
  echo "Example: $0 user@myremoteserver.com --dry-run"
  exit 1
}

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

# --- Main Logic ---

DRY_RUN=false
FORCE_OVERWRITE=false

# Parse arguments
if [ "$#" -eq 0 ]; then
  usage
fi

REMOTE_SERVER="$1"
shift # Remove the first argument (remote server)

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  --dry-run | -n)
    DRY_RUN=true
    echo "ℹ️ Dry run mode enabled. No files will actually be copied."
    ;;
  --force | -f)
    FORCE_OVERWRITE=true
    echo "⚠️ Force overwrite mode enabled. Existing files on remote will be overwritten without prompt."
    ;;
  --help | -h)
    usage
    ;;
  *)
    echo "❌ Error: Unknown option '$1'"
    usage
    ;;
  esac
  shift # Move to the next argument
done

echo "--- Dotfiles Deployment to Remote Server ---"
echo "Remote Server: $REMOTE_SERVER"
echo "Local Dotfiles Directory: $DOTFILES_DIR"
echo "------------------------------------------"

# Pre-flight check: SSH connectivity
echo "Checking SSH connectivity to $REMOTE_SERVER..."
if ! ssh -q "$REMOTE_SERVER" exit; then
  echo "❌ ERROR: Cannot connect to $REMOTE_SERVER via SSH. Please ensure SSH is working."
  echo "         You might need to add your SSH key or check your SSH configuration."
  exit 1
fi
echo "✅ SSH connection successful."

# Confirm before proceeding
if ! confirm_action "Do you want to proceed with deploying dotfiles to '$REMOTE_SERVER'? This will overwrite existing files."; then
  echo "Deployment cancelled."
  exit 0
fi

for config_name in "${!CONFIGS_TO_DEPLOY[@]}"; do
  LOCAL_PATH="${DOTFILES_DIR}/${config_name}"
  REMOTE_TARGET_SUFFIX="${CONFIGS_TO_DEPLOY[$config_name]}"
  REMOTE_TARGET_PATH="$REMOTE_SERVER:~/$REMOTE_TARGET_SUFFIX"

  echo ""
  echo "--- Deploying $config_name ---"
  echo "Source: $LOCAL_PATH"
  echo "Target: $REMOTE_SERVER:~/$REMOTE_TARGET_SUFFIX"

  if [ ! -e "$LOCAL_PATH" ]; then
    echo "❌ WARNING: Local source path for '$config_name' not found: $LOCAL_PATH. Skipping."
    continue
  fi

  # Create parent directory on remote if it doesn't exist
  REMOTE_PARENT_DIR=$(dirname "$REMOTE_TARGET_SUFFIX")
  if [[ "$REMOTE_PARENT_DIR" != "." ]]; then # Avoid trying to create '~/'
    echo "Ensuring parent directory exists on remote: $REMOTE_SERVER:~/$REMOTE_PARENT_DIR"
    if ! $DRY_RUN; then
      ssh "$REMOTE_SERVER" "mkdir -p ~/$REMOTE_PARENT_DIR"
      if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to create remote directory ~/$REMOTE_PARENT_DIR. Skipping $config_name."
        continue
      fi
    else
      echo "  (Dry run: Would create remote directory ~/$REMOTE_PARENT_DIR)"
    fi
  fi

  RSYNC_OPTIONS="-avh --progress"
  if [ "$DRY_RUN" = true ]; then
    RSYNC_OPTIONS+=" --dry-run"
  fi
  # Use --delete-after with caution if you want to mirror the directory exactly
  # RSYNC_OPTIONS+=" --delete-after"

  echo "Running rsync command..."
  if [ -d "$LOCAL_PATH" ]; then
    # If it's a directory, ensure trailing slash for rsync to copy contents
    rsync $RSYNC_OPTIONS "$LOCAL_PATH/" "$REMOTE_SERVER:~/$REMOTE_TARGET_SUFFIX/"
  else
    # If it's a file
    rsync $RSYNC_OPTIONS "$LOCAL_PATH" "$REMOTE_SERVER:~/$REMOTE_TARGET_SUFFIX"
  fi

  if [ $? -eq 0 ]; then
    echo "✅ Successfully synced '$config_name'."
  else
    echo "❌ ERROR: Failed to sync '$config_name'. See output above."
  fi
done

echo ""
echo "--- Deployment Complete ---"
echo "Next Steps (on the remote server):"
echo "💡 For Neovim:"
echo "   1. SSH into the remote server: ssh $REMOTE_SERVER"
echo "   2. Open nvim: nvim"
echo "   3. Run your plugin manager's install/sync command (e.g., :Lazy sync for lazy.nvim)."
echo ""
echo "💡 For Tmux:"
echo "   1. If you use TPM (Tmux Plugin Manager), ensure it's installed (it should be in ~/.tmux/plugins/tpm if you followed your local setup)."
echo "   2. Start tmux: tmux"
echo "   3. Inside tmux, press your prefix key (Ctrl+a by default if you use your .tmux.conf) then 'I' (capital i) to install/sync plugins."
echo "   4. If you had an existing tmux session, you might need to kill it and restart for changes to take full effect, or just source the config: tmux source-file ~/.tmux.conf"
echo ""
echo "Consider restarting your terminal session on the remote server or launching new ones to ensure all changes take effect."
echo "------------------------------------------"
