# Agent instructions

Read [RESTORE.md](RESTORE.md) before restoring or changing this repository.
It defines the installation order, architecture-specific paths, validation steps,
and the files that must remain local to each Mac.

This repository is chezmoi source state, not a normal copy of `$HOME`.
Use chezmoi naming conventions and verify every target path with
`chezmoi target-path` when adding a new file.

When changing a managed file, edit the file under `$HOME`, test it, and run
`chezmoi add <path>` to update the source state.
Review `chezmoi diff` before committing.

Shared aliases live in `~/.oh-my-zsh/custom/aliases.zsh`.
Oh My Zsh loads that file after its plugins, so these definitions can override
plugin aliases without replacing either Mac's complete `~/.zshrc`.
Do not create or manage another zshrc solely to share aliases.

The Herdr plugin manifest is a chezmoi template.
Edit `private_dot_config/herdr/plugins/window-title/herdr-plugin.toml.tmpl`
in the source directory rather than importing the rendered target with
`chezmoi add`.

Never add Herdr logs, sockets, session state, release notes, or `plugins.json`.
The plugin registry contains machine-specific absolute paths.
Restore the local window-title plugin with `herdr plugin link` instead.

Do not add Neovim data from `~/.local/share/nvim`, `~/.local/state/nvim`, or
`~/.cache/nvim`.
Keep `~/.config/nvim/lazy-lock.json` tracked because it pins plugin revisions.

Do not commit credentials, SSH keys, tokens, shell history, or machine-specific
application state.
Do not push changes unless the user explicitly asks.
