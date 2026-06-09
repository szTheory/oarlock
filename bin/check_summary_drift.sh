#!/usr/bin/env bash

# Check for uncommitted changes to ensure working tree is clean.
# In CI, enforces completely clean working tree after tests.
# Locally, blocks commits that include a SUMMARY.md if there are ANY unstaged or untracked files.

set -e

RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${RED}ERROR: Working tree is dirty in CI.${NC}"
        echo -e "${YELLOW}The following files are untracked or have uncommitted changes:${NC}"
        git status --porcelain
        echo -e "${RED}Failing the build to prevent drift.${NC}"
        exit 1
    fi
    exit 0
fi

# Local pre-commit check
if git diff --cached --name-only | grep -qE '.*-SUMMARY\.md$'; then
    # A SUMMARY.md file is staged. Check for ANY unstaged modifications or untracked files.
    # '.[^ ]' matches any line where the second character is not a space,
    # which catches ' M' (unstaged mod), 'MM' (staged and unstaged mod), '??' (untracked).
    if git status --porcelain | grep -qE '^(.[^ ])'; then
        echo -e "${RED}ERROR: You are attempting to commit a SUMMARY.md file, but your working tree is dirty.${NC}"
        echo -e "${YELLOW}The following files are unstaged or untracked:${NC}"
        git status --porcelain | grep -E '^(.[^ ])'
        echo -e "${RED}Please stage all intended changes, or stash/remove untracked files before committing a SUMMARY.md.${NC}"
        exit 1
    fi
fi

exit 0
