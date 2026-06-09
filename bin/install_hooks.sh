#!/usr/bin/env bash

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Ensure the script is executable
chmod +x bin/check_summary_drift.sh

# Symlink the hook script
HOOK_PATH=".git/hooks/pre-commit"

if [ -L "$HOOK_PATH" ] || [ -e "$HOOK_PATH" ]; then
    echo "A pre-commit hook already exists. Backing it up to ${HOOK_PATH}.bak"
    mv "$HOOK_PATH" "${HOOK_PATH}.bak"
fi

# The path in symlink must be relative to .git/hooks/
ln -s "../../bin/check_summary_drift.sh" "$HOOK_PATH"

echo "Successfully installed pre-commit hook."
