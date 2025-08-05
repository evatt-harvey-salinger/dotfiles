#!/bin/bash

# Top-level install.sh script for dotfiles projects

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of available projects (subdirectories with install.sh)
AVAILABLE_PROJECTS=(alacritty nvim tmux opencode)

usage() {
  cat <<EOF
Usage: $0 [all|project1 project2 ...]

Options:
  all           Install all projects
  project1 ...  Install specified projects (available: ${AVAILABLE_PROJECTS[*]})
  -h, --help    Show this help message
EOF
}

# Parse arguments
if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

# Determine projects to install
PROJECTS=()
if [ "$1" == "all" ]; then
  PROJECTS=("${AVAILABLE_PROJECTS[@]}")
else
  for arg in "$@"; do
    if [[ " ${AVAILABLE_PROJECTS[*]} " == *" $arg "* ]]; then
      PROJECTS+=("$arg")
    else
      echo -e "Warning: Unknown project '$arg' ignored."
    fi
  done
fi

if [ ${#PROJECTS[@]} -eq 0 ]; then
  echo -e "Error: No valid projects specified."
  usage
  exit 1
fi

# Counters
success_count=0
fail_count=0

# Run install scripts
for project in "${PROJECTS[@]}"; do
  echo -e "\n=== Installing $project ==="
  install_script="$BASE_DIR/$project/install.sh"
  if [ ! -x "$install_script" ]; then
    echo -e "Error: Install script not found or not executable for project '$project': $install_script"
    fail_count=$((fail_count + 1))
    continue
  fi

  "$install_script"
  if [ $? -eq 0 ]; then
    echo -e "Success: $project installed."
    success_count=$((success_count + 1))
  else
    echo -e "Failure: $project installation failed."
    fail_count=$((fail_count + 1))
  fi
  echo -e "========================"

done

# Summary

echo -e "\nInstallation Summary:"
echo -e "  Successful installs: $success_count"
echo -e "  Failed installs: $fail_count"

if [ $fail_count -eq 0 ]; then
  echo -e "All installations completed successfully."
  exit 0
else
  echo -e "Some installations failed. Check messages above."
  exit 1
fi
