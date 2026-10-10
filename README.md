# `fd` for Mavericks

The fast and user-friendly alternative to `find` for Mac OS X 10.9 Mavericks.

## Shell completions

Add a line to your shell startup file:

- `~/.bash_profile`: `. /usr/local/mavergreen/fd/share/bash-completion/completions/fd`
- `~/.zshrc`, before `compinit`: `fpath=(/usr/local/mavergreen/fd/share/zsh/site-functions $fpath)`
- `~/.config/fish/config.fish`: `set -p fish_complete_path /usr/local/mavergreen/fd/share/fish/vendor_completions.d`
