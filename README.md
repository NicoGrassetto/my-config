# My config

Bootstrap my terminal, tmux, and LazyVim configuration with Homebrew.

On macOS or Linux:

```sh
git clone https://github.com/NicoGrassetto/my-config.git
cd my-config
./install.sh
```

macOS also installs the configured desktop applications; Linux installs the command-line environment.

Neovim automatically opens Snacks Explorer at the project root on startup.
It includes Markdown/MDX linting, Prettier formatting, MDX language-server support, and YAML tooling.

tmux automatically balances adjacent panes when the terminal window is resized,
resetting manually adjusted pane proportions.