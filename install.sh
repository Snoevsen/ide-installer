#!/bin/bash
set -e

# --- CONFIGURATION ---
USER="Snoevsen"
REPO="ide-installer"
REPO_URL="https://github.com/$USER/$REPO.git"
PATHS_URL="https://raw.githubusercontent.com/$USER/$REPO/main/ide-paths.txt"

if ! command -v git &> /dev/null; then
    echo "Error: 'git' is required."
    exit 1
fi

# --- DETECT OPERATING SYSTEM ---
OS_TYPE="unknown"
case "$(uname -s)" in
    Linux*)     OS_TYPE="linux";;
    Darwin*)    OS_TYPE="macos";;
    CYGWIN*|MINGW*|MSYS*) OS_TYPE="windows";;
esac

if [ "$OS_TYPE" = "linux" ] && grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    echo "Error: You are running Windows Subsystem for Linux (WSL)."
    echo "To configure your Windows IDEs, please open PowerShell and use the Windows installer script."
    exit 1
fi

if [ "$OS_TYPE" = "windows" ] || [ "$OS_TYPE" = "unknown" ]; then
    echo "Error: This bash script is exclusively for macOS and native Linux."
    echo "Please use the Windows installer script."
    exit 1
fi

echo "Connecting to repository to find available IDEs..."
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

git clone --bare --quiet "$REPO_URL" "$TEMP_DIR"

# Dynamically find IDEs based on branch names
AVAILABLE_IDES=$(git --git-dir="$TEMP_DIR" for-each-ref "refs/heads/" --format='%(refname:short)' | grep '/' | cut -d'/' -f1 | sort | uniq)

if [ -z "$AVAILABLE_IDES" ]; then
    echo "No configurations are currently publicly available."
    exit 1
fi

echo ""
echo "Which IDE are you configuring?"
IDE_ARRAY=($AVAILABLE_IDES)
COUNT=${#IDE_ARRAY[@]}

for i in "${!IDE_ARRAY[@]}"; do
    NUM=$((i+1))
    echo "  $NUM) ${IDE_ARRAY[$i]}"
done

# FIX: Explicitly read from terminal so piped curl doesn't break it
read -p "Select (1-$COUNT): " IDE_CHOICE </dev/tty

if ! [[ "$IDE_CHOICE" =~ ^[0-9]+$ ]] || [ "$IDE_CHOICE" -lt 1 ] || [ "$IDE_CHOICE" -gt "$COUNT" ]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

IDE="${IDE_ARRAY[$((IDE_CHOICE-1))]}"

echo "Fetching newest configurations for $IDE..."
BRANCHES=$(git --git-dir="$TEMP_DIR" for-each-ref --sort=-committerdate "refs/heads/$IDE/" --format='%(refname:short)')

echo ""
echo "======================================"
echo "       Available Configurations       "
echo "======================================"

BRANCH_ARRAY=($BRANCHES)
STAGE_COUNT=${#BRANCH_ARRAY[@]}

for i in "${!BRANCH_ARRAY[@]}"; do
    NUM=$((i+1))
    FULL_BRANCH="${BRANCH_ARRAY[$i]}"
    DISPLAY_NAME="${FULL_BRANCH#$IDE/}"

    if [ "$i" -eq 0 ]; then
        echo "  $NUM) $DISPLAY_NAME  <-- [NEWEST]"
    else
        echo "  $NUM) $DISPLAY_NAME"
    fi
done
echo "======================================"
echo ""

# FIX: Explicitly read from terminal so piped curl doesn't break it
read -p "Select a configuration to install (1-$STAGE_COUNT): " STAGE_CHOICE </dev/tty

if ! [[ "$STAGE_CHOICE" =~ ^[0-9]+$ ]] || [ "$STAGE_CHOICE" -lt 1 ] || [ "$STAGE_CHOICE" -gt "$STAGE_COUNT" ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

SELECTED_BRANCH="${BRANCH_ARRAY[$((STAGE_CHOICE-1))]}"
CONFIG_URL="https://raw.githubusercontent.com/$USER/$REPO/$SELECTED_BRANCH/settings.json"

# --- DETERMINE INSTALLATION PATH ---
echo "Looking up installation path for $IDE on $OS_TYPE..."
PATHS_CONTENT=$(curl -fsSL "$PATHS_URL")

# Extract the path from ide-paths.txt for Linux/macOS
RAW_PATH=$(echo "$PATHS_CONTENT" | grep -i "^$IDE:$OS_TYPE:" | cut -d':' -f3-)

if [ -z "$RAW_PATH" ]; then
    echo "Error: Could not find an installation path for '$IDE' on OS '$OS_TYPE' in ide-paths.txt."
    exit 1
fi

# Safely replace the literal string $HOME with the user's actual home directory
SETTINGS_FILE="${RAW_PATH/\$HOME/$HOME}"
TARGET_DIR=$(dirname "$SETTINGS_FILE")

echo "Installing $SELECTED_BRANCH to $SETTINGS_FILE..."

mkdir -p "$TARGET_DIR"

if [ -f "$SETTINGS_FILE" ]; then
    chmod 644 "$SETTINGS_FILE"
fi

curl -fsSL "$CONFIG_URL" -o "$SETTINGS_FILE"

# Make the file read-only
chmod 444 "$SETTINGS_FILE"

echo "Successfully installed and locked $SELECTED_BRANCH config for $IDE!"
```](#)
