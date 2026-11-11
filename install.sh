#!/usr/bin/env bash
set -euo pipefail

os="$(uname -s)"
if [[ "$os" != "Darwin" && "$os" != "Linux" ]]; then
  echo "Unsupported operating system: $os" >&2
  exit 1
fi

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew was installed but could not be found." >&2
    exit 1
  fi
fi

brew install git tmux neovim tree-sitter-cli ripgrep fd fzf

git config --global user.name "NicoGrassetto"
git config --global user.email "nicograssetto@gmail.com"

if [[ "$os" == "Darwin" ]]; then
  brew install --cask font-meslo-lg-nerd-font copilot-cli
  [[ -d /Applications/Obsidian.app ]] || brew install --cask obsidian
  [[ -d /Applications/Anki.app ]] || brew install --cask anki

  if [[ ! -d /Applications/Alacritty.app ]]; then
    url="$(curl -fsSL https://api.github.com/repos/alacritty/alacritty/releases/latest | grep -o 'https://[^"]*\.dmg' | head -n1)"
    curl -fsSL "$url" -o /tmp/Alacritty.dmg
    hdiutil attach -quiet -nobrowse -mountpoint /tmp/Alacritty /tmp/Alacritty.dmg
    cp -R /tmp/Alacritty/Alacritty.app /Applications/
    hdiutil detach -quiet /tmp/Alacritty
    rm /tmp/Alacritty.dmg
  fi
fi

mkdir -p "$HOME/.config/alacritty"
curl -fsSL https://raw.githubusercontent.com/rose-pine/alacritty/main/dist/rose-pine-moon.toml \
  -o "$HOME/.config/alacritty/rose-pine-moon.toml"

cat > "$HOME/.config/alacritty/alacritty.toml" <<'EOF'
[general]
import = ["rose-pine-moon.toml"]

[window]
opacity = 0.95

[font]
normal = { family = "MesloLGM Nerd Font" }
size = 20

[colors.primary]
background = "#000000"
EOF

grep -qs git_prompt "$HOME/.zshrc" || cat >> "$HOME/.zshrc" <<'EOF'
setopt prompt_subst
git_prompt() {
  local ref=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [[ -z $ref ]] && return
  local dirty; [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty=' %F{yellow}✗'
  print -r -- "%F{blue}git:(%F{red}${ref//\%/%%}%F{blue})$dirty%f "
}
PROMPT='%B%(?.%F{green}.%F{red})➜%f  %F{cyan}%c%f $(git_prompt)%b'
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
      highlight_groups = {
        ["@type"] = { fg = "love" },
        ["@type.builtin"] = { fg = "pine" },
        ["@constant.builtin"] = { fg = "pine" },
        ["@property"] = { fg = "rose" },
        ["@variable.member"] = { fg = "rose" },
      },
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

if ! grep -Fqs 'local function open_explorer()' "$HOME/.config/nvim/lua/config/autocmds.lua"; then
  cat >> "$HOME/.config/nvim/lua/config/autocmds.lua" <<'EOF'

local function open_explorer()
  vim.schedule(function()
    Snacks.explorer({ cwd = LazyVim.root() })
  end)
end

if #vim.api.nvim_list_uis() > 0 then
  open_explorer()
else
  vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = open_explorer })
end
EOF
fi

nvim --headless -u NONE \
  "+lua local path = vim.fn.stdpath('config') .. '/lazyvim.json'; local data = vim.json.decode(table.concat(vim.fn.readfile(path), '\n')); local extra = 'lazyvim.plugins.extras.editor.fzf'; data.extras = data.extras or {}; if not vim.tbl_contains(data.extras, extra) then table.insert(data.extras, 1, extra) end; vim.fn.writefile({ vim.json.encode(data) }, path)" \
  +qa

# tmux shortcuts
# The default prefix is Ctrl+b: press and release it before the next key.
#
# Sessions (the outermost layer)
# From your shell:
#   tmux                       Start a new session.
#   tmux new -s name           Start a named session.
#   tmux ls                    List sessions.
#   tmux attach -t name        Reattach to a named session.
#   tmux a                     Reattach to the most recently used session.
#   tmux kill-session -t name  Kill a session.
# Inside tmux:
#   prefix d                  Detach; the session keeps running in the background.
#   prefix s                  Show an interactive session list.
#   prefix $                  Rename the session.
#   prefix ( / prefix )       Switch to the previous/next session.
#
# Windows (like tabs)
#   prefix c                  Create a window.
#   prefix ,                  Rename the window.
#   prefix n / prefix p       Go to the next/previous window.
#   prefix 0-9                Jump to a window by number.
#   prefix w                  Show an interactive window/session tree.
#   prefix &                  Close the window, with confirmation.
#
# Panes (splits)
#   prefix %                  Split left/right.
#   prefix "                  Split top/bottom.
#   prefix arrow keys         Move between panes.
#   prefix o                  Cycle through panes.
#   prefix z                  Zoom/unzoom the current pane.
#   prefix x                  Close the pane, with confirmation.
#   prefix { / prefix }       Swap pane positions.
#   prefix Space              Cycle through layouts.
#   prefix Ctrl+arrow         Resize panes; hold Ctrl while repeating the arrow.
#
# Scrolling and copying
#   prefix [                  Enter copy/scroll mode.
#   arrows / PgUp / PgDn      Scroll in copy mode; q exits.
#   Ctrl+s / Ctrl+r           Search forward/backward with emacs-style keys.
#   Ctrl+Space                Start a selection with emacs-style keys.
#   Alt+w                     Copy the selection and exit with emacs-style keys.
#   prefix ]                  Paste.
# With set -g mode-keys vi, use / and ? to search, Space to select, and Enter
# to copy. Using v to select and y to yank requires custom copy-mode-vi bindings.
#
# Misc
#   prefix ?                  List all keybindings.
#   prefix :                  Open the tmux command prompt.
#   setw synchronize-panes    Toggle typing in all panes from that prompt.
#   prefix t                  Show a clock.
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

cat > "$HOME/.tmux.conf" <<'EOF'
set-hook -g window-resized 'select-layout -E'

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'rose-pine/tmux'
set -g @plugin 'sainnhe/tmux-fzf'
set -g @rose_pine_variant 'moon'
set -g @rose_pine_bar_bg_disable 'on'
set -g @rose_pine_bar_bg_disabled_color_option 'default'
run '~/.tmux/plugins/tpm/tpm'
EOF

"$HOME/.tmux/plugins/tpm/bin/install_plugins"
nvim --headless "+Lazy! sync" +qa


# My wallpapers:
# https://alphacoders.com/pixel-art-wallpapers