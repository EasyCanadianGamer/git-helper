#!/usr/bin/env bash
# git-setup.sh – Interactive script to configure Git and set up SSH keys for GitHub

set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────

print_step() { echo -e "\n\033[1;34m==> $*\033[0m"; }
print_ok()   { echo -e "\033[1;32m[✓] $*\033[0m"; }
print_warn() { echo -e "\033[1;33m[!] $*\033[0m"; }
print_err()  { echo -e "\033[1;31m[✗] $*\033[0m" >&2; }

ask_yes_no() {
    # Usage: ask_yes_no "Question?" [default_yes]
    local prompt="$1"
    local default="${2:-}"
    local answer
    while true; do
        if [[ "$default" == "y" ]]; then
            read -r -p "$prompt [Y/n] " answer
            answer="${answer:-y}"
        else
            read -r -p "$prompt [y/N] " answer
            answer="${answer:-n}"
        fi
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# ── 1. Git identity ───────────────────────────────────────────────────────────

print_step "Git identity configuration"

current_name="$(git config --global user.name 2>/dev/null || true)"
current_email="$(git config --global user.email 2>/dev/null || true)"

read -r -p "Enter your Git username${current_name:+ (current: $current_name)}: " git_name
git_name="${git_name:-$current_name}"
if [[ -z "$git_name" ]]; then
    print_err "Git username cannot be empty."
    exit 1
fi

read -r -p "Enter your Git email${current_email:+ (current: $current_email)}: " git_email
git_email="${git_email:-$current_email}"
if [[ -z "$git_email" ]]; then
    print_err "Git email cannot be empty."
    exit 1
fi

git config --global user.name  "$git_name"
git config --global user.email "$git_email"
print_ok "Git identity set to: $git_name <$git_email>"

# ── 2. SSH key detection ──────────────────────────────────────────────────────

print_step "Checking for existing SSH key for <$git_email>"

SSH_DIR="$HOME/.ssh"
existing_key=""

# Search all public keys whose comment matches the supplied email
if [[ -d "$SSH_DIR" ]]; then
    while IFS= read -r pub_file; do
        # SSH public keys have the format: <type> <key> [comment …]
        # Use cut to grab field 3 onward (the comment may contain spaces).
        comment="$(cut -d' ' -f3- "$pub_file" 2>/dev/null | xargs || true)"
        if [[ "$comment" == "$git_email" ]]; then
            existing_key="${pub_file%.pub}"   # path without .pub
            break
        fi
    done < <(find "$SSH_DIR" -maxdepth 1 -name "*.pub" 2>/dev/null)
fi

# ── 3a. Key already exists ────────────────────────────────────────────────────

if [[ -n "$existing_key" ]]; then
    print_ok "Found SSH key: ${existing_key}.pub"

    if ask_yes_no "Has this key already been added to your GitHub account?"; then
        print_ok "Great – your SSH key is already on GitHub. You're all set!"
    else
        print_step "Starting the SSH agent and adding your key"
        # eval is the standard, idiomatic way to load ssh-agent environment
        # variables (SSH_AUTH_SOCK, SSH_AGENT_PID) into the current shell.
        eval "$(ssh-agent -s)"
        ssh-add "$existing_key"
        print_ok "Key added to the SSH agent."

        echo
        print_warn "Copy the public key below and add it to GitHub:"
        print_warn "  GitHub → Settings → SSH and GPG keys → New SSH key"
        echo
        cat "${existing_key}.pub"
        echo
    fi

# ── 3b. No key found ─────────────────────────────────────────────────────────

else
    print_warn "No SSH key found for <$git_email>."

    if ! ask_yes_no "Would you like to generate a new SSH key?" "y"; then
        echo "Skipping SSH key generation. You can run this script again at any time."
        exit 0
    fi

    print_step "Generating a new ed25519 SSH key"

    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    key_path="$SSH_DIR/id_ed25519_github"
    # If default name is already taken, append a counter
    counter=1
    while [[ -f "$key_path" ]]; do
        key_path="$SSH_DIR/id_ed25519_github_$counter"
        (( counter++ ))
    done

    ssh-keygen -t ed25519 -C "$git_email" -f "$key_path"
    print_ok "SSH key generated: $key_path"

    print_step "Starting the SSH agent and adding the new key"
    # eval is the standard, idiomatic way to load ssh-agent environment
    # variables (SSH_AUTH_SOCK, SSH_AGENT_PID) into the current shell.
    eval "$(ssh-agent -s)"
    ssh-add "$key_path"
    print_ok "Key added to the SSH agent."

    # Persist agent info across sessions (optional ssh config entry)
    config_file="$SSH_DIR/config"
    if ! grep -q "IdentityFile $key_path" "$config_file" 2>/dev/null; then
        # Create the file with restricted permissions before writing to it
        # so that it is never briefly world-readable.
        if [[ ! -f "$config_file" ]]; then
            install -m 600 /dev/null "$config_file"
        fi
        {
            echo ""
            echo "Host github.com"
            echo "  HostName github.com"
            echo "  User git"
            echo "  IdentityFile $key_path"
            echo "  AddKeysToAgent yes"
        } >> "$config_file"
        chmod 600 "$config_file"
        print_ok "Added GitHub entry to $config_file"
    fi

    echo
    print_warn "Copy the public key below and add it to your GitHub account:"
    print_warn "  GitHub → Settings → SSH and GPG keys → New SSH key"
    echo
    cat "${key_path}.pub"
    echo
fi

# ── 4. Done ───────────────────────────────────────────────────────────────────

print_step "Setup complete"
print_ok "Git user : $git_name <$git_email>"
print_ok "Test your connection with: ssh -T git@github.com"
