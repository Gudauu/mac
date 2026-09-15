-- Keymaps that do not belong to a specific plugin.
--
-- Design rule for this config: your vim muscle memory keeps working. Almost
-- everything here hangs off <leader> (space), which is unmapped in stock vim.
-- The two exceptions are flagged inline.

local map = vim.keymap.set

-- <Esc> in normal mode does nothing useful in stock vim, so reusing it to
-- clear search highlighting costs you nothing.
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- ---------------------------------------------------------------- clipboard
-- Explicit system-clipboard access. Plain y/d/p stay on vim's own registers.
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
map('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })
map({ 'n', 'v' }, '<leader>p', '"+p', { desc = 'Paste from system clipboard' })

-- ---------------------------------------------------------------- windows
-- EXCEPTION 1: this shadows builtins. <C-h> is a synonym for `h`, <C-l> is
-- "redraw screen", <C-j>/<C-k> are line motions. All four have better-known
-- equivalents (h, :redraw, j, k), and dropping the <C-w> prefix for window
-- movement is worth it. Delete this block if you disagree.
map('n', '<C-h>', '<C-w>h', { desc = 'Go to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Go to lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Go to upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Go to right window' })

-- ---------------------------------------------------------------- diagnostics
-- Note: neovim 0.11+ already gives you `]d` and `[d` to jump between
-- diagnostics, and <C-w>d to open the one under the cursor. These are extras.
-- <leader>e used to be the diagnostics float. It now opens the file explorer
-- (see lua/plugins/explorer.lua), which is the more common convention and the
-- key you will reach for far more often.
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Show line diagnostics' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })

-- ---------------------------------------------------------------- terminal
-- <Esc> inside a :terminal sends Esc to the shell, so you need a different
-- key to get back to normal mode. This is the conventional one.
map('t', '<C-\\><C-n>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
