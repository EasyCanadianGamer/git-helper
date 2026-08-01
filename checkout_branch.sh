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

current_branch=$(git branch --show-current)
new_branch_option="✨ Create new branch"

# Build the list of local branches, marking the current one
branches=$(git branch --format='%(refname:short)' | grep -v "^${current_branch}$")

choice=$(printf "%s\n%s\n" "$new_branch_option" "$branches" | gum choose --header "🌿 Currently on '$current_branch' — checkout which branch?")

# User pressed Esc/Ctrl+C
if [ -z "$choice" ]; then
    echo "No branch selected. Exiting."
    exit 0
fi

if [ "$choice" == "$new_branch_option" ]; then
    new_branch=$(gum input --placeholder "Enter new branch name")

    if [ -z "$new_branch" ]; then
        echo "No branch name entered. Exiting."
        exit 1
    fi

    git checkout -b "$new_branch"
else
    git checkout "$choice"
fi
