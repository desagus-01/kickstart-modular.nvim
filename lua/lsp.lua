-- lua/lsp.lua
-- LSP configuration for Neovim 0.12+
-- Server configs live in ~/.config/nvim/lsp/*.lua

-- ── Diagnostics ──────────────────────────────────────────────────
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = true },
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
    source = true,
    spacing = 2,
    format = function(diagnostic)
      return diagnostic.message
    end,
  },
}

-- ── Capabilities (builtin autocomplete) ───────────────────────
-- Enable snippet support for all servers (0.12 builtin)
vim.lsp.config('*', {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
          resolveSupport = { properties = { 'documentation', 'detail', 'additionalTextEdits' } },
        },
      },
    },
  },
})

-- Pre-warm LuaSnip on first real file so snippets are ready
vim.api.nvim_create_autocmd('InsertEnter', {
  once = true,
  callback = function()
    pcall(require, 'luasnip')
  end,
})

-- ── LspAttach keymaps & highlights ──────────────────────────────
local detach_group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = false })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- grn (rename), gra (code action), grr (references), gri (implementations),
    -- grt (type def), gO (document symbols), Ctrl-S (signature help)
    -- are all built-in defaults in 0.12 — only override the ones we want via Telescope
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

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    local big = vim.api.nvim_buf_line_count(event.buf) > 5000
    if (not big) and client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
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

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- ── Enable servers ──────────────────────────────────────────────
vim.lsp.enable {
  'lua_ls',
  'rust_analyzer',
  'pyrefly',
  -- 'zls',
  'terraformls',
  -- 'dockerls',
  -- 'docker_compose_language_service',
}

-- ── On-type formatting (0.12) ───────────────────────────────────
-- Automatically formats as you type (e.g. auto-indent after newline)
pcall(function()
  vim.lsp.on_type_formatting.enable()
end)
