-- Entry point. Neovim reads this file on startup.
--
-- Anything in lua/ is loadable by `require`, where a dot is a directory
-- separator: require('config.options') loads lua/config/options.lua.

-- The leader key must be set BEFORE plugins load. Plugins bake the current
-- value of mapleader into their keymaps at definition time, so setting it
-- later silently gives you the wrong bindings.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.lazy') -- bootstraps the plugin manager, which loads lua/plugins/
