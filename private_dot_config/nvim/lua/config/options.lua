-- Everything you would have put in the top of a .vimrc.
--
-- Neovim already turns these ON by default, which is why you will not find
-- them here even though every vim tutorial tells you to set them:
--
--   syntax on              filetype plugin indent on    set nocompatible
--   incsearch              hlsearch                     wildmenu
--   autoindent             smarttab                     ttyfast
--   backspace=indent,eol,start                          autoread
--   encoding=utf-8         history=10000                showcmd
--
-- Run `:help nvim-defaults` for the authoritative list.

local opt = vim.opt

-- ---------------------------------------------------------------- line numbers
opt.number = true
opt.relativenumber = true -- distances for `5j` / `12k`. Set false if you hate it.

-- ---------------------------------------------------------------- indentation
-- These are global fallbacks. Treesitter and LSP-aware plugins override them
-- per language, and any project with an .editorconfig wins over both (neovim
-- has editorconfig support built in since 0.9).
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true -- `>>` rounds to a multiple of shiftwidth

-- ---------------------------------------------------------------- search
opt.ignorecase = true
opt.smartcase = true -- ...unless the pattern contains a capital letter

-- ---------------------------------------------------------------- ui
opt.signcolumn = 'yes' -- always reserve the gutter, so text stops shifting
                       -- sideways every time a diagnostic appears
opt.cursorline = true
opt.scrolloff = 8      -- keep 8 lines of context above/below the cursor
opt.sidescrolloff = 8
-- Soft wrap at the window edge. This only changes how a long line is *drawn*;
-- the file on disk still holds one long line, so nothing reflows on save.
opt.wrap = true
opt.linebreak = true   -- break at a space, not mid-word
opt.breakindent = true -- continuation lines keep the original indent
opt.showbreak = '↳ '   -- marker so a wrapped line is not mistaken for a real one
opt.termguicolors = true -- 24-bit color. Required by every modern colorscheme.
opt.splitbelow = true    -- `:split` opens below, not above
opt.splitright = true    -- `:vsplit` opens right, not left

-- Show the whitespace that actually causes problems, hide the rest.
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- ---------------------------------------------------------------- files
opt.undofile = true -- undo history persists across restarts, in
                    -- ~/.local/state/nvim/undo. This is one of the single
                    -- biggest quality-of-life wins over stock vim.
opt.swapfile = false
opt.backup = false

-- ---------------------------------------------------------------- timing
opt.updatetime = 250  -- how long before CursorHold fires. LSP hover-on-idle
                      -- and git blame both key off this. Default 4000 is glacial.
opt.timeoutlen = 400  -- how long to wait for the rest of a mapping sequence

-- ---------------------------------------------------------------- completion
opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- ---------------------------------------------------------------- neovim extras
-- Live preview of :s///, shown in a split. There is no vim equivalent.
-- Type `:%s/foo/bar/g` and watch it happen before you hit enter.
opt.inccommand = 'split'

-- Briefly highlight text you just yanked, so you can see what `y` grabbed.
-- (wired up in autocmds.lua)

-- ---------------------------------------------------------------- clipboard
-- Deliberately NOT set. `opt.clipboard = 'unnamedplus'` would route every
-- y/d/p through the macOS clipboard, which means `d` clobbers whatever you
-- copied from your browser. Explicit <leader>y / <leader>p keymaps do the
-- same job without the surprise. Uncomment the line below if you decide you
-- want the automatic version after all.
--
-- vim.schedule(function() vim.opt.clipboard = 'unnamedplus' end)
