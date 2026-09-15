-- Autocommands. Same concept as vim's :autocmd, but the lua API groups them
-- so re-sourcing your config does not stack duplicates.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Flash the text you just yanked. Purely cosmetic, but it makes it obvious
-- when a `y` grabbed more or less than you meant.
autocmd('TextYankPost', {
  group = augroup('highlight_yank', { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Restore the cursor to where you were last time you had this file open.
-- The classic .vimrc one-liner, in lua.
autocmd('BufReadPost', {
  group = augroup('restore_cursor', { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- herdr's edit_scrollback action (prefix+u) dumps the focused pane's scrollback
-- to a temp file and opens it in $EDITOR. Seed the search so that prefix+u on
-- its own is the entire "jump to my last prompt" gesture, with no typing after.
--
-- The pattern is the glyph Claude Code prints before every user prompt. This
-- autocmd is agent-agnostic: it fires for any herdr scrollback. Other agents
-- mark prompts differently (codex uses a block glyph, not this one), so extend
-- this into a branch like [[❯\|▌]] once you have confirmed their marker.
local herdr_prompt_pattern = [[❯]]

autocmd('BufReadPost', {
  group = augroup('herdr_scrollback', { clear = true }),
  pattern = '*herdr-scrollback-*',
  callback = function(args)
    -- Scrollback can reach the 50 MB per-pane cap set in herdr's config. Undo
    -- history is on globally, and persisting it for a buffer you read once and
    -- throw away costs real seconds and litters ~/.local/state/nvim/undo.
    vim.bo[args.buf].undofile = false
    vim.bo[args.buf].syntax = ''

    -- Loading the register rather than running a search means n and N work
    -- immediately, and every prompt stays highlighted while you move.
    vim.fn.setreg('/', herdr_prompt_pattern)
    vim.o.hlsearch = true

    -- The prompt you want is nearly always the most recent one, so start at the
    -- bottom and search backwards. 'c' accepts a match on the last line itself.
    vim.cmd('normal! G')
    if vim.fn.search(herdr_prompt_pattern, 'bcW') > 0 then
      vim.cmd('normal! zz')
    end
  end,
})

-- Strip trailing whitespace on save, except where it is significant.
autocmd('BufWritePre', {
  group = augroup('trim_whitespace', { clear = true }),
  callback = function(args)
    -- Trailing whitespace is significant in markdown (two spaces = line break)
    -- and structural in diffs, so leave those alone.
    if vim.bo[args.buf].filetype == 'markdown' or vim.bo[args.buf].filetype == 'diff' then
      return
    end
    -- Scratch and read-only buffers (checkhealth output, :help, plugin uis)
    -- can be written but not modified. Substituting in them throws E21.
    if not vim.bo[args.buf].modifiable or vim.bo[args.buf].buftype ~= '' then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
