#!/bin/bash
set -e

# --- CONFIGURATION ---
USER="Snoevsen"
REPO="ide-installer"
REPO_URL="https://github.com/$USER/$REPO.git"

# --- GIT INSTALLATION CHECK ---
if ! command -v git &> /dev/null; then
    echo "Error: 'git' is required to fetch available configurations."
    exit 1
fi

echo "Fetching available configurations from $USER/$REPO..."

# Fetch branches starting with 'stage-' and sort reverse-alphabetically
BRANCHES=$(git ls-remote --heads "$REPO_URL" | awk -F'refs/heads/' '{print $2}' | grep '^stage-' | sort -r)

if [ -z "$BRANCHES" ]; then
    echo "No configurations are currently publicly available."
    exit 1
fi

echo ""
echo "======================================"
echo "       Available Configurations       "
echo "======================================"

BRANCH_ARRAY=($BRANCHES)

for i in "${!BRANCH_ARRAY[@]}"; do
    NUM=$((i+1))
    BRANCH_NAME="${BRANCH_ARRAY[$i]}"
    if [ "$i" -eq 0 ]; then
        echo "  $NUM) $BRANCH_NAME  <-- [NEWEST]"
    else
        echo "  $NUM) $BRANCH_NAME"
    fi
done
echo "======================================"
echo ""
echo "Test successful! The script can read the branches."
