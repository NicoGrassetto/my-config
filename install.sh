#!/usr/bin/env bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install curl git
else
    # Linux (Debian/Ubuntu)
    sudo apt update
    sudo apt install -y curl git build-essential pkg-config libssl-dev
fi

command -v rustup >/dev/null || curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env"

cargo install --locked helix-term zellij
mkdir -p ~/.config/{helix,zellij}
