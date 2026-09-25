#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

brew install git tmux neovim tree-sitter-cli ripgrep fd
brew install --cask font-jetbrains-mono-nerd-font copilot-cli

if [[ ! -d /Applications/Alacritty.app ]]; then
  url="$(curl -fsSL https://api.github.com/repos/alacritty/alacritty/releases/latest | grep -o 'https://[^"]*\.dmg' | head -n1)"
  curl -fsSL "$url" -o /tmp/Alacritty.dmg
  hdiutil attach -quiet -nobrowse -mountpoint /tmp/Alacritty /tmp/Alacritty.dmg
  cp -R /tmp/Alacritty/Alacritty.app /Applications/
  hdiutil detach -quiet /tmp/Alacritty
  rm /tmp/Alacritty.dmg
fi

mkdir -p "$HOME/.config/alacritty"
curl -fsSL https://raw.githubusercontent.com/rose-pine/alacritty/main/dist/rose-pine-moon.toml \
  -o "$HOME/.config/alacritty/rose-pine-moon.toml"

cat > "$HOME/.config/alacritty/alacritty.toml" <<'EOF'
[general]
import = ["rose-pine-moon.toml"]

[window]
opacity = 0.9

[font]
normal = { family = "JetBrainsMono Nerd Font" }
EOF

if [[ ! -d "$HOME/.config/nvim" ]]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

mkdir -p "$HOME/.config/nvim/lua/plugins"
cat > "$HOME/.config/nvim/lua/plugins/rose-pine.lua" <<'EOF'
return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "moon",
      styles = { transparency = true },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
}
EOF

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

cat > "$HOME/.tmux.conf" <<'EOF'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'rose-pine/tmux'
set -g @rose_pine_variant 'moon'
set -g @rose_pine_bar_bg_disable 'on'
set -g @rose_pine_bar_bg_disabled_color_option 'default'
run '~/.tmux/plugins/tpm/tpm'
EOF

"$HOME/.tmux/plugins/tpm/bin/install_plugins"
nvim --headless "+Lazy! sync" +qa
