-- Treesitter: real parsing instead of regex highlighting.
--
-- IMPORTANT, and the reason most copy-pasted configs break here: nvim-treesitter
-- was rewritten. The `main` branch (used below, requires neovim 0.12) is a
-- completely different plugin from the `master` branch that every older blog
-- post and video shows. If you find a snippet online using
-- `require('nvim-treesitter.configs').setup { highlight = { enable = true } }`,
-- that is the OLD api and it will not work here.
--
-- The new branch only installs parsers. Highlighting, folding and indentation
-- are neovim features that you switch on yourself, which is what the autocmd
-- at the bottom of this file does.

local languages = {
  'bash', 'c', 'cpp', 'css', 'diff', 'dockerfile', 'git_config', 'gitcommit',
  'gitignore', 'go', 'html', 'javascript', 'json', 'lua', 'luadoc',
  'make', 'markdown', 'markdown_inline', 'python', 'query', 'regex', 'rust',
  'sql', 'toml', 'tsx', 'typescript', 'vim', 'vimdoc', 'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,       -- this plugin explicitly does not support lazy-loading
    build = ':TSUpdate', -- parsers are version-locked to the plugin; this keeps
                         -- them in sync whenever the plugin updates
    config = function()
      require('nvim-treesitter').install(languages)

      -- Turn on treesitter features per filetype. Neovim provides all three;
      -- the plugin only supplies the parsers and queries they read.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
        callback = function(args)
          -- Only real file buffers. Plugin uis are scratch buffers that set a
          -- filetype of their own -- blink.cmp's completion menu uses
          -- `blink-cmp-menu` -- and there is obviously no parser by that name.
          if vim.bo[args.buf].buftype ~= '' then
            return
          end

          local ft = vim.bo[args.buf].filetype
          local lang = vim.treesitter.language.get_lang(ft)
          if not lang then
            return
          end

          -- No parser installed for this filetype, leave it to regex syntax.
          --
          -- Both halves of this check matter. `language.add` RETURNS nil on
          -- failure instead of raising, so the pcall status alone is always
          -- true and says nothing; the returned value is the real answer.
          local ok, has_parser = pcall(vim.treesitter.language.add, lang)
          if not ok or not has_parser then
            return
          end

          vim.treesitter.start(args.buf, lang)

          -- Folding driven by code structure: `zc` closes the function you are
          -- inside of. foldlevel 99 means everything starts open.
          --
          -- FileType can fire for a buffer that is not the one on screen (a
          -- plugin calling bufload, `:bufdo`), and window-local options would
          -- then land on whatever window happens to be current. Only touch
          -- them when this buffer really is the current window's.
          if vim.api.nvim_win_get_buf(0) == args.buf then
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
            vim.wo[0][0].foldlevel = 99
          end

          -- Structural indentation. Marked experimental upstream; if `=` or
          -- auto-indent ever misbehaves in a language, delete this line.
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  {
    -- Text objects built from the syntax tree. This is the part vim genuinely
    -- cannot do: `vaf` selects a whole function, `dif` deletes a function body,
    -- `cia` changes an argument, regardless of language.
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
      })

      local select = require('nvim-treesitter-textobjects.select')
      local pairs_map = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
      }
      for lhs, capture in pairs(pairs_map) do
        vim.keymap.set({ 'x', 'o' }, lhs, function()
          select.select_textobject(capture, 'textobjects')
        end, { desc = 'Select ' .. capture })
      end
    end,
  },
}
