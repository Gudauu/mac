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

The managed `~/.zshrc` owns the shared Oh My Zsh bootstrap and plugin list.
Shared aliases and the prompt live in `~/.oh-my-zsh/custom/aliases.zsh` and
`~/.oh-my-zsh/custom/prompt.zsh`.
Third-party plugins are pinned in `.chezmoiexternal.toml`.
Keep device-specific paths, runtimes, and key bindings in the unmanaged
`~/.zshrc.local` file loaded by the managed zshrc.
Before replacing an existing zshrc on another Mac, preserve its device-specific
statements in `.zshrc.local`; do not copy a second Oh My Zsh bootstrap there.

The AeroSpace config and Herdr plugin manifest are chezmoi templates.
Edit `dot_aerospace.toml.tmpl` and
`private_dot_config/herdr/plugins/window-title/herdr-plugin.toml.tmpl` in the
source directory rather than importing their rendered targets with
`chezmoi add`.
Both templates select Homebrew paths for the current Mac architecture.

Never add Herdr logs, sockets, session state, release notes, or `plugins.json`.
The plugin registry contains machine-specific absolute paths.
Restore the local window-title plugin with `herdr plugin link` instead.

Do not add Neovim data from `~/.local/share/nvim`, `~/.local/state/nvim`, or
`~/.cache/nvim`.
Keep `~/.config/nvim/lazy-lock.json` tracked because it pins plugin revisions.

Do not commit credentials, SSH keys, tokens, shell history, or machine-specific
application state.
Do not push changes unless the user explicitly asks.
