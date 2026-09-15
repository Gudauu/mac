-- Colorscheme and statusline.

return {
  {
    'folke/tokyonight.nvim',
    lazy = false,    -- the colorscheme is needed immediately, not on demand
    priority = 1000, -- load it before everything else so there is no flash
    opts = {
      style = 'night', -- 'storm' | 'night' | 'moon' | 'day'
    },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme('tokyonight')
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy', -- lazy.nvim's "after the UI is drawn" event
    opts = {
      options = {
        theme = 'tokyonight',
        globalstatus = true, -- one statusline for the whole window, not per split
        section_separators = '',
        component_separators = '|',
      },
      sections = {
        lualine_c = { { 'filename', path = 1 } }, -- path relative to cwd
      },
    },
  },

  {
    -- Press <leader> and pause: a popup lists every key that could come next.
    -- This is how you rediscover your own bindings three weeks from now.
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'helix',
    },
  },
}
