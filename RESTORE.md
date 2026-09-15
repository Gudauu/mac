# Restore the macOS development configuration

This repository restores the shared configuration for Ghostty, Herdr, Neovim,
and the shell environment with chezmoi.
It also records the Homebrew packages and macOS menu shortcuts needed to make
the configuration behave the same on another Mac.

The procedure does not copy caches, logs, active terminal sessions, application
window positions, credentials, or other machine-specific state.

## What chezmoi manages

| Target | Purpose |
|---|---|
| `~/Brewfile` | Homebrew formulae, casks, and the Nerd Font |
| `~/.zshenv` | Environment variables, including `EDITOR` and `VISUAL` |
| `~/.config/ghostty/config` | Ghostty theme and background settings |
| `~/.config/herdr/config.toml` | Herdr theme, behavior, and keybindings |
| `~/.config/herdr/plugins/window-title/` | Source for the local Herdr window-title plugin |
| `~/.config/nvim/` | Neovim settings, mappings, plugins, and plugin lock file |

Herdr owns terminal tab and pane shortcuts.
They live in the `[keys]` section of `~/.config/herdr/config.toml`.
Neovim shortcuts live in its Lua configuration.
Ghostty currently delegates tab and pane handling to Herdr.

## Before restoring

Use the same macOS account for the restore.
Run the commands as that account, not with `sudo`, unless a step says otherwise.

On a Mac that already has configuration files, back them up before applying the
repository:

```sh
backup="$HOME/config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"

for path in \
  "$HOME/.zshenv" \
  "$HOME/.config/ghostty" \
  "$HOME/.config/herdr" \
  "$HOME/.config/nvim"
do
  if [[ -e "$path" ]]; then
    cp -a "$path" "$backup/"
  fi
done
```

## 1. Install Apple's command-line tools

```sh
xcode-select --install
```

Wait for the installer to finish before continuing.
Confirm that Git is available:

```sh
git --version
```

## 2. Install Homebrew

Use Homebrew's official installer:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the installer's instruction to add Homebrew to the current shell.
The normal prefix is `/opt/homebrew` on Apple Silicon and `/usr/local` on Intel.

Confirm the installation:

```sh
brew --prefix
brew doctor
```

## 3. Install chezmoi and fetch this repository

```sh
brew install chezmoi
```

For a new Mac with no configuration to preserve, fetch and apply in one step:

```sh
chezmoi init --apply https://github.com/Gudauu/mac.git
```

If the repository requires SSH authentication, use:

```sh
chezmoi init --apply git@github.com:Gudauu/mac.git
```

On a Mac that already has configuration, inspect the changes first:

```sh
chezmoi init https://github.com/Gudauu/mac.git
chezmoi diff
chezmoi apply
```

The repository maps `Brewfile` to `~/Brewfile`.
Applying chezmoi writes the file but does not install its packages.

## 4. Install the applications and command-line dependencies

```sh
brew bundle --file="$HOME/Brewfile"
```

Confirm the core programs:

```sh
herdr --version
nvim --version
"/Applications/Ghostty.app/Contents/MacOS/ghostty" +version
python3 --version
rg --version
```

The tracked `.zshenv` chooses `/opt/homebrew/bin/nvim` on Apple Silicon and
`/usr/local/bin/nvim` on Intel.
It sets both `EDITOR` and `VISUAL`.

The same file currently sources `~/.cargo/env` and contains paths for Flutter
and the Android SDK.
Install those tools if the device needs them.
If Rust is intentionally absent, guard or remove the Cargo source line in the
managed `.zshenv`, then record that change with chezmoi.

Load the restored environment in the current terminal:

```sh
exec zsh
```

Verify it:

```sh
printf 'EDITOR=%s\nVISUAL=%s\n' "$EDITOR" "$VISUAL"
command -v "$EDITOR"
```

## 5. Register the Herdr plugin

Do not restore `~/.config/herdr/plugins.json` from another Mac.
It contains absolute paths from the machine where Herdr registered each plugin.
Register the managed plugin on this Mac instead:

```sh
herdr plugin link "$HOME/.config/herdr/plugins/window-title" --enabled
herdr plugin list
```

Chezmoi renders the Python path in the plugin manifest for the current
architecture.
It uses `/opt/homebrew/bin/python3` on Apple Silicon and
`/usr/local/bin/python3` on Intel.
Confirm the rendered command before linking:

```sh
grep '^command' \
  "$HOME/.config/herdr/plugins/window-title/herdr-plugin.toml"
```

Validate the Herdr configuration:

```sh
herdr config check
```

## 6. Start the persistent Herdr service

Herdr's scrollback editor runs under the background service and does not source
zsh startup files.
Export `EDITOR` while Homebrew creates the service so the generated launchd
property list records the absolute Neovim path:

```sh
export EDITOR="$(command -v nvim)"
brew services stop herdr 2>/dev/null || true
brew services start herdr
```

Verify the recorded value:

```sh
plutil -extract EnvironmentVariables.EDITOR raw \
  "$HOME/Library/LaunchAgents/homebrew.mxcl.herdr.plist"
```

The output should match `command -v nvim`.
Do not add this generated property list to chezmoi.
Homebrew owns it and may regenerate it during service changes.

Reload and inspect Herdr:

```sh
herdr server reload-config
herdr status server
herdr plugin list
```

## 7. Bootstrap Neovim

The first launch clones `lazy.nvim` and installs the plugins pinned in
`~/.config/nvim/lazy-lock.json`:

```sh
nvim
```

Inside Neovim, run:

```vim
:Lazy sync
:MasonInstall lua-language-server basedpyright ruff
:MasonInstall typescript-language-server bash-language-server
:MasonInstall jdtls json-lsp yaml-language-server
:TSUpdate
:checkhealth
:checkhealth vim.lsp
```

The Neovim configuration enables `clangd` from Apple's command-line tools.
It does not install `clangd` through Mason.

Java development needs a JDK 21 or newer to run `jdtls` and JDK 17 for Gradle
project imports:

```sh
brew install openjdk openjdk@17
```

Follow the caveats printed by those formulae so `/usr/libexec/java_home` can
find both installations.
The Java-specific setup is optional if this Mac will not edit Java projects.

## 8. Validate Ghostty

```sh
"/Applications/Ghostty.app/Contents/MacOS/ghostty" +validate-config
open -a Ghostty
```

The Ghostty preference file under `~/Library/Preferences` is intentionally not
managed.
It contains window position and updater state rather than the shared terminal
configuration.

## 9. Restore the macOS menu shortcuts

The source Mac has these global custom menu shortcuts:

| Menu command | Shortcut |
|---|---|
| `Lock Screen` | Command+O |
| `No Action` | Command+H |
| `Shut Down` | Command+Shift+O |

Add them without replacing unrelated entries already present on the target:

```sh
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add \
  "Lock Screen" "@o"

defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add \
  "No Action" "@h"

defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add \
  "Shut Down" '@$o'
```

In these values, `@` means Command and `$` means Shift.
Menu command names depend on the macOS system language.
Log out and back in after changing them.

If "shortcuts" means workflows in Apple's Shortcuts app, enable Shortcuts in
iCloud settings on both Macs.
Those workflows sync through iCloud and do not belong in this repository.

## 10. Final checks

```sh
chezmoi doctor
chezmoi diff
brew services list
herdr config check
herdr plugin list
"/Applications/Ghostty.app/Contents/MacOS/ghostty" +validate-config
```

`chezmoi diff` should print nothing after a clean restore.
Open Ghostty, start Herdr, and press the backtick prefix followed by the configured
Herdr keys to test tab and pane actions.
Open Neovim and press Space, then wait for which-key to show the available
mappings.

## Keeping another Mac current

On the Mac where a configuration changed, test the live file first and record
it in chezmoi:

```sh
chezmoi add "$HOME/.zshenv"
chezmoi add "$HOME/.config/ghostty/config"
chezmoi add "$HOME/.config/herdr/config.toml"
chezmoi add "$HOME/.config/herdr/plugins/window-title/window_title.py"
chezmoi add "$HOME/.config/nvim"
chezmoi diff
```

Add only paths that actually changed.
The Herdr plugin manifest is a template because its Python path depends on the
Homebrew architecture.
Edit that file from the source directory instead of importing its rendered
target:

```sh
chezmoi cd
nvim private_dot_config/herdr/plugins/window-title/herdr-plugin.toml.tmpl
exit
chezmoi diff
```

Commit and push from the source directory:

```sh
chezmoi cd
git status
git add <changed-source-paths>
git commit
git push
exit
```

On every other Mac, review and apply the update:

```sh
chezmoi git pull --ff-only
chezmoi diff
chezmoi apply
```

Then reload the affected program:

```sh
herdr config check && herdr server reload-config
```

Restart Ghostty after its configuration changes.
Restart Neovim after its configuration changes and run `:Lazy sync` if the
plugin specification or lock file changed.

## Files that must stay local

Never add these paths to the repository:

```text
~/.config/herdr/*.log
~/.config/herdr/*.sock
~/.config/herdr/plugins.json
~/.config/herdr/plugins.json.bak
~/.config/herdr/session.json
~/.config/herdr/sessions/
~/.config/herdr/release-notes.json
~/.local/share/nvim/
~/.local/state/nvim/
~/.cache/nvim/
~/Library/Preferences/com.mitchellh.ghostty.plist
~/Library/LaunchAgents/homebrew.mxcl.herdr.plist
```

They contain runtime state, generated data, caches, or machine-specific paths.
