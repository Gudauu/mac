-- File explorers.
--
-- Why this file exists at all: `:Explore` (netrw, vim's built-in explorer) is
-- switched off in lua/config/lazy.lua under `disabled_plugins`. That is why
-- typing `:Explore` gives you "Not an editor command". Two plugins split that
-- job. Oil replaces it: a directory is an ordinary buffer, and editing that
-- text is how you create, rename, move and delete files.
--
-- The neo-tree spec below is kept but switched off (`enabled = false`), so the
-- sidebar and everything configured for it is one line away from coming back.

return {
  {
    'nvim-neo-tree/neo-tree.nvim',

    -- Retired in favour of oil. lazy.nvim skips a disabled spec entirely: no
    -- clone, no keymaps, no autocmds, no startup cost. `:Lazy clean` will offer
    -- to delete the copy already on disk; say yes, it re-clones if you flip
    -- this back to true.
    enabled = false,

    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- filetype icons, needs the Nerd Font you
                                     -- already have installed
      'MunifTanjim/nui.nvim',        -- the popup/input widgets neo-tree draws with
    },

    -- Load neo-tree when you press one of the keys below, or when you launch
    -- nvim on a directory (`nvim .`). Without the second half, `nvim .` would
    -- hand you an empty buffer because netrw is not there to catch it.
    cmd = 'Neotree',
    keys = {
      { '<leader>e', '<cmd>Neotree toggle<CR>',           desc = 'File explorer (toggle)' },
      { '<leader>E', '<cmd>Neotree reveal<CR>',           desc = 'File explorer (reveal current file)' },
      { '<leader>ge', '<cmd>Neotree float git_status<CR>', desc = 'Git status tree' },
    },
    init = function()
      -- Claim the directory-argument case before anything else can.
      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('neotree_dir_start', { clear = true }),
        callback = function(args)
          if vim.fn.isdirectory(args.file) == 1 then
            require('neo-tree')
            return true -- one-shot: delete this autocmd once it has fired
          end
        end,
      })
    end,

    opts = {
      close_if_last_window = true, -- do not leave a lone sidebar as the whole
                                   -- editor after you close your last file
      popup_border_style = 'rounded',
      enable_git_status = true,
      enable_diagnostics = true,

      window = {
        width = 34,
        mappings = {
          -- Neo-tree's defaults are already vim-flavoured (j/k to move, q to
          -- close). These are the additions worth knowing about.
          ['<CR>'] = 'open',
          ['l'] = 'open',        -- expand folder / open file, like a tree in any editor
          ['h'] = 'close_node',  -- collapse. l/h to walk the tree beats arrow keys.
          ['s'] = 'open_split',
          ['v'] = 'open_vsplit',
          ['P'] = { 'toggle_preview', config = { use_float = true } },
          ['H'] = 'toggle_hidden',
        },
      },

      filesystem = {
        -- Keep the tree pointed at whatever file you are editing, and highlight
        -- it. Without this the sidebar drifts out of sync the moment you jump
        -- somewhere with telescope.
        follow_current_file = { enabled = true, leave_dirs_open = false },

        -- Let neo-tree change nvim's cwd when you navigate into a directory
        -- with it. Off by default; on means <leader>ff searches where you are
        -- actually looking.
        bind_to_cwd = true,
        cwd_target = { sidebar = 'tab', current = 'window' },

        -- Watch the filesystem instead of polling, so files created by git,
        -- a build, or an agent show up without a manual refresh.
        use_libuv_file_watcher = true,

        filtered_items = {
          visible = false,      -- start with the noise collapsed; `H` reveals it
          hide_dotfiles = true,
          hide_gitignored = true,
          never_show = { '.DS_Store' },
        },
      },
    },
  },

  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },

    -- `-` is unmapped in stock vim's normal mode in any way you would miss
    -- (it is "first non-blank of previous line", which `k^` already does), so
    -- this does not cost you muscle memory. It is oil's own convention too.
    keys = {
      { '-', '<cmd>Oil<CR>', desc = 'Open parent directory (oil)' },
      -- <leader>e was neo-tree's. Keeping the key pointed at "file explorer"
      -- means the reflex still works; it just lands in a float now.
      { '<leader>e', function() require('oil').open_float() end, desc = 'File explorer (oil, float)' },
    },
    cmd = 'Oil',

    -- With neo-tree gone, oil has to be loaded eagerly enough to catch
    -- `nvim .`, which the lazy `keys`/`cmd` triggers above would miss.
    lazy = false,

    opts = {
      -- Nothing else claims a directory argument now that netrw is off and
      -- neo-tree is disabled, so `nvim .` should land in an oil buffer.
      default_file_explorer = true,

      -- Deletes go to a scratch trash buffer you can undo out of, not straight
      -- to unlink(2). This is the setting that makes editing a directory as
      -- text feel safe.
      delete_to_trash = true,

      -- Save without a "are you sure" prompt for the obvious cases (create,
      -- rename, move). Deletes still ask, since those are the ones you cannot
      -- eyeball from the diff.
      skip_confirm_for_simple_edits = true,

      -- Keep oil's view in sync with what is actually on disk while it is open.
      watch_for_changes = true,

      view_options = {
        show_hidden = false, -- `g.` toggles
      },

      columns = { 'icon' },

      float = {
        -- <leader>e's float previews into a split of the float itself. "auto"
        -- picks a side from the window shape; pin it right so the preview is
        -- in the same place whether you came in via `-` or via the float.
        preview_split = 'right',
      },

      keymaps = {
        -- oil's defaults, minus the ones that fight this config: it maps <C-h>
        -- and <C-l> for splits/refresh, which would shadow the window-movement
        -- keys in lua/config/keymaps.lua. Rebound onto the <C-s>/<C-v> pair
        -- that neo-tree's s/v mappings already train you on.
        ['<C-h>'] = false,
        ['<C-l>'] = false,
        ['<C-s>'] = { 'actions.select', opts = { horizontal = true } },
        ['<C-v>'] = { 'actions.select', opts = { vertical = true } },
        ['<C-r>'] = 'actions.refresh',

        -- Preview the entry under the cursor in a vertical split. `splitright`
        -- is on, so it lands to the right of the oil buffer and oil keeps the
        -- left pane; `preview_win.update_on_cursor_moved` (on by default) then
        -- refreshes it as you move down the listing. <C-p> again closes it.
        ['<C-p>'] = 'actions.preview',
        ['<C-d>'] = 'actions.preview_scroll_down',
        ['<C-u>'] = 'actions.preview_scroll_up',

        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
        ['`'] = 'actions.cd',
        ['gs'] = 'actions.change_sort',
        ['gx'] = 'actions.open_external',
        ['g.'] = 'actions.toggle_hidden',
        ['g\\'] = 'actions.toggle_trash',
        ['q'] = 'actions.close',
      },
      use_default_keymaps = false, -- the table above is the whole set
    },
  },
}
