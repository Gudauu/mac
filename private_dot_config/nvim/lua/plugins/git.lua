-- Git, at three levels of zoom.
--
--   gitsigns   one buffer, one hunk. The gutter, `]c`, and staging a hunk
--              without leaving the file you are editing.
--   diffview   one change set. Every modified file side by side, or the
--              history of a file, or a whole branch reviewed as one diff.
--   neogit     the repository. Status, staging, commit, push, rebase.
--
-- Only gitsigns loads at startup, because only it has to draw on every buffer
-- you open. The other two are registered as commands and keymaps that lazy.nvim
-- resolves on first press, so they cost nothing until used (`:Lazy profile`).

return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = false, -- toggled with <leader>gb below
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = 'eol',
      },
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation. `]c` and `[c` are vim's builtin diff-mode hunk motions,
        -- so this extends a binding you may already know rather than inventing one.
        map('n', ']c', function() gs.nav_hunk('next') end, 'Next git hunk')
        map('n', '[c', function() gs.nav_hunk('prev') end, 'Previous git hunk')

        -- Staging. This is `git add -p` without leaving the buffer.
        map('n', '<leader>gs', gs.stage_hunk, 'Stage hunk')
        map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('v', '<leader>gs', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage selection')
        map('v', '<leader>gr', function() gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Reset selection')
        map('n', '<leader>gS', gs.stage_buffer, 'Stage whole buffer')
        -- Note: stage_hunk toggles. Press <leader>gs again on an already-staged
        -- hunk to unstage it. (The old undo_stage_hunk function is deprecated.)

        -- Inspection
        map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame line')
        map('n', '<leader>gB', gs.toggle_current_line_blame, 'Toggle inline blame')
        map('n', '<leader>gd', gs.diffthis, 'Diff against index')
        map('n', '<leader>gD', function() gs.diffthis('~') end, 'Diff against last commit')

        -- Text object: `dih` deletes the hunk under the cursor, `vih` selects it.
        map({ 'o', 'x' }, 'ih', gs.select_hunk, 'Select git hunk')
      end,
    },
  },

  {
    -- Multi-file diff. This is the piece vim's builtin `:diffsplit` and
    -- gitsigns' `<leader>gd` cannot do: they show one file, this shows a
    -- change set. A file panel on the left, the diff on the right, `<tab>`
    -- and `<s-tab>` to walk the files, `q` to close.
    --
    -- Also the only comfortable merge conflict resolver in the ecosystem:
    -- `:DiffviewOpen` during a conflicted merge lays out ours / base / theirs.
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles' },
    keys = {
      { '<leader>gv', '<cmd>DiffviewOpen<CR>',          desc = 'Diff working tree' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'History of this file' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<CR>',   desc = 'History of this repo' },
    },
    opts = {
      -- Highlights the changed words within a changed line, not just the line.
      enhanced_diff_hl = true,
      view = {
        -- diff3_mixed shows ours and theirs above the working copy during a
        -- conflict, so `<leader>co` / `ct` / `cb` have something to point at.
        merge_tool = { layout = 'diff3_mixed' },
      },
    },
  },

  {
    -- Repository status and staging, in the magit style: a single buffer
    -- listing untracked / unstaged / staged sections, where `s` stages what is
    -- under the cursor and `u` unstages it, at whatever granularity you have
    -- expanded to (section, file, or hunk).
    --
    -- The commands are popups rather than keymaps to memorise. `?` lists them,
    -- and `c`, `p`, `r`, `b` open the commit, push, rebase and branch menus,
    -- each showing its own flags as toggles.
    'NeogitOrg/neogit',
    cmd = 'Neogit',
    keys = {
      { '<leader>gg', '<cmd>Neogit<CR>', desc = 'Git status' },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',          -- already present, telescope pulls it in
      'sindrets/diffview.nvim',         -- makes `d` in the status buffer useful
      'nvim-telescope/telescope.nvim',  -- branch / commit pickers
    },
    opts = {
      graph_style = 'unicode',
      integrations = { diffview = true, telescope = true },
    },
  },
}
