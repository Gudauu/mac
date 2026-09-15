-- Bootstraps lazy.nvim, the plugin manager.
--
-- On first launch there is no plugin manager on disk, so we git-clone it
-- ourselves before using it. Every lazy.nvim config on the internet starts
-- with some version of this block.

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- `import` tells lazy.nvim to load every file under lua/plugins/ and treat
  -- what each returns as a plugin spec. Adding a plugin = adding a file, or
  -- adding a table to an existing one. No central list to keep in sync.
  spec = { { import = 'plugins' } },

  -- Do not auto-check for updates in the background. Run `:Lazy update`
  -- when you actually want to.
  checker = { enabled = false },
  change_detection = { notify = false },

  -- None of the plugins here are luarocks packages. Left on, lazy.nvim tries
  -- to bootstrap a private lua 5.1 + luarocks and `:checkhealth` reports an
  -- error forever. Flip this back on if you ever add a rocks-based plugin.
  rocks = { enabled = false },

  -- Neovim ships with a pile of legacy vim plugins loaded by default. Nothing
  -- here uses them, and disabling them shaves startup time.
  --
  -- `netrwPlugin` stays off deliberately: it is what provides `:Explore`, and
  -- neo-tree (lua/plugins/explorer.lua) does that job better. If you ever want
  -- `:Explore` back, delete 'netrwPlugin' from this list.
  --
  -- `tutor` is NOT disabled, because `:Tutor` is the built-in 30-minute
  -- interactive vim lesson and it is worth keeping while you are learning.
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip', 'tarPlugin', 'tohtml', 'zipPlugin', 'netrwPlugin',
      },
    },
  },
})
