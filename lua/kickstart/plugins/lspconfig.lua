return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'mason-org/mason.nvim', cmd = 'Mason', opts = {} },
      { 'WhoIsSethDaniel/mason-tool-installer.nvim', event = 'VeryLazy' },
      { 'j-hui/fidget.nvim', opts = {}, event = 'LspAttach' },
    },
    config = function()
      local detach_group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = false })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          map('grr', function()
            require('telescope.builtin').lsp_references()
          end, '[G]oto [R]eferences')
          map('gri', function()
            require('telescope.builtin').lsp_implementations()
          end, '[G]oto [I]mplementation')
          map('grd', function()
            require('telescope.builtin').lsp_definitions()
          end, '[G]oto [D]efinition')
          map('gO', function()
            require('telescope.builtin').lsp_document_symbols()
          end, 'Open Document Symbols')
          map('gW', function()
            require('telescope.builtin').lsp_dynamic_workspace_symbols()
          end, 'Open Workspace Symbols')
          map('grt', function()
            require('telescope.builtin').lsp_type_definitions()
          end, '[G]oto [T]ype Definition')

          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            end
            return client.supports_method(method, { bufnr = bufnr })
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          local big = vim.api.nvim_buf_line_count(event.buf) > 5000
          if (not big) and client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_group = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_group,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_group,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = detach_group,
              buffer = event.buf,
              callback = function(ev2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = ev2.buf }
              end,
            })
          end

          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            return diagnostic.message
          end,
        },
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, 'blink.cmp')
      if ok_blink and blink and blink.get_lsp_capabilities then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local servers = {
        zls = {},
        clangd = {
          keys = {
            { '<leader>ch', '<cmd>ClangdSwitchSourceHeader<cr>', desc = 'Switch Source/Header (C/C++)' },
          },
          root_dir = function(fname)
            local util = require 'lspconfig.util'
            return util.root_pattern('compile_commands.json', 'compile_flags.txt', 'Makefile', 'meson.build', 'build.ninja', '.git')(fname)
          end,
          capabilities = {
            offsetEncoding = { 'utf-16' },
          },
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders',
            '--fallback-style=llvm',
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          inlayHints = {
            Enabled = true,
            ParameterNames = true,
            DeducedTypes = true,
            Designators = true,
          },
        },
        rust_analyzer = {},
        pyrefly = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
            },
          },
        },
        terraformls = {},
        dockerls = {},
        docker_compose_language_service = {},
      }

      local ensure_installed = {
        'lua-language-server',
        'rust-analyzer',
        'zls',
        'terraform-ls',
        'pyrefly',
        'stylua',
        'tflint',
        'hadolint',
        'ruff',
      }
      vim.schedule(function()
        pcall(function()
          require('mason-tool-installer').setup { ensure_installed = ensure_installed }
        end)
      end)

      for name, server in pairs(servers) do
        server = server or {}
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },
}
