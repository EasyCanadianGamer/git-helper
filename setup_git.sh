#!/bin/bash

echo "🚀 Starting Git Configuration..."
echo "-----------------------------------"

# Ask for Name
read -p "Enter your Git User Name: " git_name
# Ask for Email
read -p "Enter your Git Email: " git_email

# Set the Config
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# --- Quality of Life Tweaks ---
# Sets the default branch to 'main'
git config --global init.defaultBranch main
# Uses your favorite terminal editor (Kitty/Micro/Nano)
git config --global core.editor "nano"
# Colors the output for easier reading in the terminal
git config --global color.ui auto

echo "-----------------------------------"
echo "✅ Git is now configured!"
echo "User: $(git config --global user.name)"
echo "Email: $(git config --global user.email)"
echo "-----------------------------------"
