#!/bin/bash

echo "🔐 Starting SSH Key Generation for GitHub..."
echo "-------------------------------------------"

# 1. Ask for Email
read -p "Enter your GitHub email address: " github_email

# 2. Generate the Key (using Ed25519 as recommended)
# -t ed25519: Modern, secure, and small
# -C: Adds a label (your email)
ssh-keygen -t ed25519 -C "$github_email"

# 3. Start the ssh-agent in the background
eval "$(ssh-agent -s)"

# 4. Add the private key to the agent
# Note: This assumes the default name id_ed25519
ssh-add ~/.ssh/id_ed25519

echo "-------------------------------------------"
echo "✅ SSH Key Generated and added to agent!"
echo "-------------------------------------------"
echo "👉 COPY THE TEXT BELOW AND ADD IT TO GITHUB:"
echo "Settings -> SSH and GPG keys -> New SSH key"
echo ""
cat ~/.ssh/id_ed25519.pub
echo ""
echo "-------------------------------------------"
