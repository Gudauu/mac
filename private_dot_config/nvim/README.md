# neovim config

Built for Neovim 0.12.
Leader key is `<Space>`.

## Layout

```
init.lua                    entry point, sets leader, requires the rest
lua/config/options.lua      what used to be the top of your .vimrc
lua/config/keymaps.lua      non-plugin keymaps
lua/config/autocmds.lua     yank highlight, cursor restore, trim whitespace
lua/config/lazy.lua         plugin manager bootstrap + settings
lua/plugins/ui.lua          colorscheme, statusline, which-key
lua/plugins/editor.lua      telescope (fuzzy finding)
lua/plugins/treesitter.lua  parsing, highlighting, folds, text objects
lua/plugins/lsp.lua         language servers, completion, mason
lua/plugins/git.lua         gitsigns
```

Adding a plugin means adding a table to one of the `lua/plugins/` files, or adding a new file there.
There is no central list to keep in sync.

## Day one

Your vim knowledge transfers completely.
Everything below is additive.

The single most useful habit: press `<Space>` and wait.
which-key pops up showing every binding available from there.
You do not need to memorize this file.

### Discovering things

| Key | Does |
|---|---|
| `<Space>` then wait | Show all leader bindings |
| `<leader>fk` | Search all keymaps, including ones you forgot |
| `<leader>fh` | Search the help docs |
| `:Lazy` | Plugin manager UI. `U` updates, `x` cleans |
| `:Mason` | Install / remove language servers |
| `:checkhealth` | Diagnose anything that seems broken |

### Finding files and text

| Key | Does |
|---|---|
| `<leader>ff` | Find file by name |
| `<leader>fg` | Grep across the project |
| `<leader>fw` | Grep the word under the cursor |
| `<leader>fb` | Switch buffer |
| `<leader>fr` | Recently opened files |
| `<leader>/` | Fuzzy search within the current buffer |
| `<leader>fd` | All diagnostics in the project |

Inside a telescope window: `<C-n>` / `<C-p>` to move, `<CR>` to open, `<C-v>` / `<C-x>` to open in a split, `<Esc>` to close.

### Language server

Most of these are Neovim 0.11+ builtins, not custom bindings.
They work in any config, which is why they are worth learning.

| Key | Does |
|---|---|
| `K` | Hover documentation |
| `<C-]>` | Go to definition, then `<C-t>` to jump back |
| `gd` | Go to definition |
| `grn` | Rename symbol across the project |
| `gra` | Code action (quick fixes, imports) |
| `grr` | List all references |
| `gri` | Go to implementation |
| `gO` | Document symbol outline |
| `]d` / `[d` | Next / previous diagnostic |
| `<leader>e` | Show the diagnostic on this line |
| `<leader>lf` | Format the buffer |

Note the `gr` prefix: it is a Neovim 0.11 convention, not something invented here.

### Completion

Fires automatically as you type in insert mode.

| Key | Does |
|---|---|
| `<C-n>` / `<C-p>` | Next / previous item |
| `<C-e>` | Accept |
| `<C-y>` | Dismiss |
| `<C-space>` | Force open, or show docs |

`<Tab>` is deliberately left alone, so it still indents.

### Git

| Key | Does |
|---|---|
| `]c` / `[c` | Next / previous changed hunk |
| `<leader>gs` | Stage hunk. Press again to unstage |
| `<leader>gr` | Reset hunk |
| `<leader>gp` | Preview the hunk inline |
| `<leader>gb` | Blame this line, with commit message |
| `<leader>gB` | Toggle always-on inline blame |
| `<leader>gd` | Diff this file against the index |
| `dih` / `vih` | Delete / select the hunk under the cursor |

`<leader>gs` in visual mode stages only the selected lines.
That covers most of what `git add -p` is for.

### Treesitter text objects

These work by parsing the language, so they behave the same in Python, C++, and TypeScript.

| Key | Does |
|---|---|
| `vaf` / `vif` | Select a function, with or without its signature |
| `dif` | Delete a function body |
| `vac` / `vic` | Select a class |
| `cia` | Change an argument |
| `zc` / `zo` | Fold / unfold the block you are inside |

### Misc

| Key | Does |
|---|---|
| `<Esc>` | Clear search highlighting |
| `<C-h/j/k/l>` | Move between windows without the `<C-w>` prefix |
| `<leader>y` / `<leader>p` | Yank / paste via the macOS clipboard |

## Things that differ from vim

Persistent undo is on.
Close a file, reopen it tomorrow, and `u` still walks back through yesterday's edits.

`:%s/foo/bar/g` previews live in a split before you press enter, because `inccommand` is set.

The system clipboard is NOT wired to plain `y` and `p`.
That is deliberate, so that `d` does not clobber something you copied from a browser.
If you want the automatic behavior, uncomment the last line of `lua/config/options.lua`.

Trailing whitespace is stripped on save, except in markdown and diffs.
See `lua/config/autocmds.lua` if you want that gone.

## Adding a language

Two independent steps.

1. Parser, for highlighting.
   Add the name to the `languages` list in `lua/plugins/treesitter.lua`, then restart and run `:TSUpdate`.

2. Language server, for intelligence.
   Find it in `:Mason`, press `i` to install.
   Then add its lspconfig name to the `servers` list in `lua/plugins/lsp.lua`.

The two names often differ.
Mason calls it `lua-language-server`; lspconfig calls it `lua_ls`.

## Installed servers

`lua_ls`, `basedpyright`, `ruff`, `ts_ls`, `clangd`, `bashls`, `jsonls`, `yamlls`.

`clangd` comes from Xcode at `/usr/bin/clangd` and was not installed through Mason.
For it to work well on a C++ project, that project needs a `compile_commands.json`.

## Gotchas worth knowing

nvim-treesitter was rewritten.
This config uses the `main` branch.
Any tutorial showing `require('nvim-treesitter.configs').setup { highlight = { enable = true } }` is the old `master` API and will not work here.

LSP setup also changed in 0.11.
This config uses `vim.lsp.enable('server')`.
Tutorials showing `require('lspconfig').pyright.setup{}` are the older API.
It still functions, but it is being phased out.

## If something breaks

```
:Lazy                  plugin states, load times, errors
:checkhealth           the broad diagnostic
:checkhealth vim.lsp   which servers attached to this buffer, and why not
:messages              errors that scrolled past
```

Older guides mention `:LspInfo`.
nvim-lspconfig removed it; `:checkhealth vim.lsp` replaced it.

To bisect a bad plugin, comment it out of its `lua/plugins/` file and restart.
