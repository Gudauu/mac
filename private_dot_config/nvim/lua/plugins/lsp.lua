-- Language servers: go-to-definition, rename, diagnostics, completion.
--
-- Neovim 0.11 moved LSP configuration into core. The modern api is
-- `vim.lsp.enable('server_name')`, and nvim-lspconfig's only job now is to
-- ship the per-server default settings that enable() reads off the
-- runtimepath. If you see `require('lspconfig').pyright.setup{}` in a tutorial,
-- that is the pre-0.11 api. It still works, but it is on the way out.

-- Servers to turn on. Each name must have a definition in nvim-lspconfig, and
-- the corresponding binary must exist on your PATH (see :Mason).
local servers = {
  'lua_ls',       -- lua, and it understands the neovim api
  'basedpyright', -- python types
  'ruff',         -- python lint + format, extremely fast
  'ts_ls',        -- typescript / javascript
  'clangd',       -- c / c++
  'bashls',       -- shell
  'jdtls',        -- java (eclipse jdt language server)
  'jsonls',
  'yamlls',
}

-- Resolve a JDK home from a `/usr/libexec/java_home` version selector such as
-- '1.8', '17' or '21+'. Returns nil unless the answer is a real JDK: on macOS
-- the selector '1.8' is happily answered by the Java applet plugin, which is a
-- JRE and has no compiler, so `bin/javac` is the honest test.
local function jdk_home(selector)
  local out = vim.fn.system({ '/usr/libexec/java_home', '-v', selector })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local home = vim.trim(out)
  return vim.uv.fs_stat(home .. '/bin/javac') and home or nil
end

-- Same, but falls back to scanning the standard install directory. Needed for
-- old versions, where java_home's preferred answer is the applet plugin JRE.
local function jdk_home_or_scan(selector, pattern)
  local home = jdk_home(selector)
  if home then
    return home
  end
  for _, dir in ipairs(vim.fn.glob('/Library/Java/JavaVirtualMachines/*/Contents/Home', false, true)) do
    if dir:match(pattern) and vim.uv.fs_stat(dir .. '/bin/javac') then
      return dir
    end
  end
  return nil
end

return {
  {
    -- Installs language servers into ~/.local/share/nvim/mason so you do not
    -- have to npm/pip install each one by hand. Run `:Mason` for the ui.
    'mason-org/mason.nvim',
    -- All of these must be listed, not just `Mason`. lazy.nvim only creates
    -- stub commands for the names given here, so omitting MasonInstall means
    -- `:MasonInstall foo` errors with "not an editor command" until you have
    -- opened the `:Mason` ui at least once in that session.
    cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonUpdate', 'MasonLog' },
    opts = {},
  },

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'mason-org/mason.nvim', 'saghen/blink.cmp' },
    config = function()
      -- Tell every server what this client can do. blink.cmp advertises extra
      -- completion capabilities, so servers send back richer results.
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      -- ------------------------------------------------------------ java
      -- jdtls needs more hand-holding than the other servers, for three
      -- reasons that all bite silently if left alone.
      local mason = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
      local jdtls_jvm = jdk_home('21+')
      local gradle_jvm = jdk_home('17')

      -- 1. Lombok. The compiler plugin generates getters, setters and
      --    builders at build time, so without the javaagent jdtls sees none of
      --    them and paints every `getFoo()` call as an undefined-method error.
      --    The shipped jdtls config turns this env var into --jvm-arg=... for
      --    us. The name is jdtls-specific, so exporting it is harmless.
      vim.env.JDTLS_JVM_ARGS = '-javaagent:' .. mason .. '/lombok.jar'

      vim.lsp.config('jdtls', {
        -- 2. The JVM that runs jdtls itself. Recent builds refuse to start on
        --    anything below 21, and a shell that exported an older JAVA_HOME
        --    for a build would otherwise be inherited here. cmd_env scopes the
        --    override to the server process, so `:terminal ./gradlew` still
        --    sees whatever you actually set.
        cmd_env = jdtls_jvm and { JAVA_HOME = jdtls_jvm } or nil,

        settings = {
          java = {
            configuration = {
              -- Lets a project compile against an older source level than the
              -- JVM jdtls runs on, instead of warning on every buffer.
              runtimes = vim.tbl_filter(function(rt)
                return rt.path ~= nil
              end, {
                { name = 'JavaSE-1.8', path = jdk_home_or_scan('1.8', '8') },
                { name = 'JavaSE-17', path = jdk_home('17') },
                { name = 'JavaSE-21', path = jdk_home('21') },
              }),
            },
            import = {
              gradle = {
                -- 3. The JVM that runs the Gradle import. Gradle only accepts
                --    JVMs up to a few versions past its own release, so a
                --    current JDK makes older wrappers die at configuration
                --    time with "Unsupported class file major version". 17 is
                --    the version every Gradle 7 and 8 wrapper can run on. This
                --    is jdtls's project import only, not your builds.
                java = { home = gradle_jvm },
              },
            },
          },
        },
      })

      vim.lsp.enable(servers)

      -- How diagnostics are displayed.
      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = { prefix = '●', spacing = 2 },
        float = { border = 'rounded', source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN]  = '󰀪 ',
            [vim.diagnostic.severity.INFO]  = '󰋽 ',
            [vim.diagnostic.severity.HINT]  = '󰌶 ',
          },
        },
      })

      -- Buffer-local keymaps, set only once a server actually attaches.
      --
      -- Neovim 0.11+ ALREADY gives you these by default, so they are not
      -- repeated here:
      --   K       hover documentation
      --   grn     rename symbol
      --   gra     code action
      --   grr     list references
      --   gri     go to implementation
      --   grt     go to type definition
      --   gO      document symbols
      --   <C-]>   go to definition (via tagfunc, so your vim tag muscle
      --           memory works unchanged, including <C-t> to jump back)
      --   ]d [d   next / previous diagnostic
      -- Attaching is not the same as being ready. jdtls replies to `initialize`
      -- with almost no capabilities (definitionProvider is absent), then
      -- registers them a moment later over client/registerCapability, once the
      -- project import has produced a classpath. LspAttach fires on the reply,
      -- so these keymaps exist during a window in which the server genuinely
      -- does not support the request, and a `gd` pressed there prints
      --   method "textDocument/definition" is not supported by any server
      -- which reads as a broken config rather than "not yet". The window is
      -- about half a second on a warm jdtls workspace and far longer on a cold
      -- one, where Gradle has to resolve dependencies first.
      --
      -- So wait for the capability instead of failing on it. vim.wait keeps the
      -- event loop running, which is what lets the registration arrive while we
      -- block, and it returns early if you press a key, so a server that never
      -- registers costs you one keystroke rather than the full timeout.
      local function when_supported(method, fn)
        return function()
          local buf = vim.api.nvim_get_current_buf()
          local function supported()
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
              if client:supports_method(method, buf) then
                return true
              end
            end
            return false
          end

          if not supported() then
            vim.notify('Waiting for the language server to be ready...', vim.log.levels.INFO)
            vim.wait(30000, supported, 100)
          end
          fn()
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
        callback = function(args)
          local function map(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end

          -- Shadows the builtin `gd` (go to local declaration). The LSP version
          -- is strictly more useful, and <C-]> covers the same ground. Note
          -- that <C-]> goes through tagfunc, so it still fails outright inside
          -- the not-ready window described above. Prefer `gd` on a cold jdtls.
          map('gd', when_supported('textDocument/definition', vim.lsp.buf.definition), 'Go to definition')
          map('<leader>ls', vim.lsp.buf.signature_help, 'Signature help')
          map('<leader>lf', function()
            vim.lsp.buf.format({ async = true })
          end, 'Format buffer')

          -- Highlight other occurrences of the symbol under the cursor.
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight') then
            local hl_group = vim.api.nvim_create_augroup('lsp_highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              group = hl_group,
              buffer = args.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              group = hl_group,
              buffer = args.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  {
    -- Completion. blink.cmp is a single plugin with a prebuilt binary, which
    -- is why it is here instead of the older nvim-cmp plus its six companion
    -- plugins for sources and snippets.
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '1.*', -- release tags ship a compiled fuzzy matcher, so you do
                     -- not need a rust toolchain
    opts = {
      -- The 'default' preset is deliberately vim-flavoured:
      --   <C-n> / <C-p>  next / previous item, same as vim's builtin completion
      --   <C-e>          accept
      --   <C-y>          cancel
      --   <C-space>      open menu / show docs
      -- Notably <Tab> is NOT stolen, so it still indents.
      keymap = {
        preset = 'default',
        ['<C-e>'] = { 'select_and_accept', 'fallback' },
        ['<C-y>'] = { 'cancel', 'fallback' },
      },

      appearance = { nerd_font_variant = 'mono' },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },
}
