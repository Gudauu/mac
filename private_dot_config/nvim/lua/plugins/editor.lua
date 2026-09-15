-- Fuzzy finding. This is the plugin you will use most.

return {
  {
    'nvim-telescope/telescope.nvim',
    -- Not '0.1.x': that tag predates the nvim-treesitter `main` rewrite and its
    -- previewer still calls the removed nvim-treesitter.parsers.ft_to_lang.
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim', -- lua stdlib that half the ecosystem depends on
      {
        -- Native C sorter. Without it telescope gets sluggish in big repos
        -- (you have ClickHouse checked out, so you want this).
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
      },
    },
    cmd = 'Telescope',
    keys = {
      -- Declaring keys here means telescope is not loaded until you press one.
      { '<leader>ff', '<cmd>Telescope find_files<CR>',  desc = 'Find files' },
      { '<leader>fg', '<cmd>Telescope live_grep<CR>',   desc = 'Grep in project' },
      { '<leader>fb', '<cmd>Telescope buffers<CR>',     desc = 'Find buffer' },
      { '<leader>fh', '<cmd>Telescope help_tags<CR>',   desc = 'Find help tag' },
      { '<leader>fr', '<cmd>Telescope oldfiles<CR>',    desc = 'Recent files' },
      { '<leader>fw', '<cmd>Telescope grep_string<CR>', desc = 'Grep word under cursor' },
      { '<leader>fd', '<cmd>Telescope diagnostics<CR>', desc = 'Diagnostics' },
      { '<leader>fk', '<cmd>Telescope keymaps<CR>',     desc = 'Find keymap' },

      -- Symbol search. Unlike <leader>fg, these ask the language server, so
      -- they find the *declaration* of a class or function rather than every
      -- line that happens to mention its name. Both need an LSP attached to
      -- the buffer (lua/plugins/lsp.lua); with no server they say so and stop.
      { '<leader>fs', '<cmd>Telescope lsp_document_symbols<CR>', desc = 'Symbols in this file' },
      -- "dynamic" = re-queries the server on every keystroke instead of
      -- fuzzy-filtering one fixed result set. The non-dynamic version asks for
      -- every symbol in the project up front, which stalls on a big repo.
      { '<leader>fS', '<cmd>Telescope lsp_dynamic_workspace_symbols<CR>', desc = 'Symbols in project' },

      -- Reopen the last picker with its query and cursor position intact.
      -- The one you will be glad exists after closing a result by mistake.
      { '<leader>f<CR>', '<cmd>Telescope resume<CR>', desc = 'Resume last picker' },
      -- Fuzzy search inside the current buffer. Replaces / when you do not
      -- know the exact spelling.
      { '<leader>/',  '<cmd>Telescope current_buffer_fuzzy_find<CR>', desc = 'Search in buffer' },
    },
    -- opts is a FUNCTION, not a table, because it calls require() on telescope's
    -- own modules. Spec tables are evaluated at startup, before telescope is on
    -- the runtimepath, so a plain table here would crash on first launch.
    opts = function()
      local actions = require('telescope.actions')
      return {
        defaults = {
          mappings = {
            i = {
              -- In vim, <C-u> clears the line. Telescope's insert mode should
              -- match that rather than scrolling the preview.
              ['<C-u>'] = false,
              ['<Esc>'] = actions.close, -- one Esc closes, no need to leave insert first

              -- Walk the result list without leaving insert mode. Telescope
              -- ships <C-n>/<C-p> for this and leaves <C-j>/<C-k> unmapped;
              -- these match the j/k direction sense you already use for window
              -- movement in lua/config/keymaps.lua. <C-n>/<C-p> still work.
              ['<C-j>'] = actions.move_selection_next,
              ['<C-k>'] = actions.move_selection_previous,
            },
          },
          -- Ignore noise. Add project-specific ignores here as you hit them.
          file_ignore_patterns = { '%.git/', 'node_modules/', '%.venv/', 'venv/' },
        },
        pickers = {
          find_files = { hidden = true }, -- show dotfiles, still respects .gitignore
        },
      }
    end,
    config = function(_, opts)
      require('telescope').setup(opts)
      require('telescope').load_extension('fzf')
    end,
  },
}
