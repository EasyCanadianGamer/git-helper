#!/bin/bash

# Requires gum: https://github.com/charmbracelet/gum
if ! command -v gum &> /dev/null; then
    echo "❌ gum is not installed. Install it first: https://github.com/charmbracelet/gum#installation"
    exit 1
fi

# Bail out early if we're not inside a git repo
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "❌ Not a git repository."
    exit 1
fi

# Build the list of changed/untracked files (porcelain status, path only)
files=$(git status --porcelain | sed 's/^...//')

if [ -z "$files" ]; then
    echo "✅ Nothing to commit, working tree clean."
    exit 0
fi

selected=$(echo "$files" | gum choose --no-limit --header "📦 Select files to stage")

if [ -z "$selected" ]; then
    echo "No files selected. Exiting."
    exit 0
fi

while IFS= read -r file; do
    git add -- "$file"
done <<< "$selected"

message=$(gum input --placeholder "Enter commit message")

if [ -z "$message" ]; then
    echo "No commit message entered. Exiting."
    exit 1
fi

git commit -m "$message"
