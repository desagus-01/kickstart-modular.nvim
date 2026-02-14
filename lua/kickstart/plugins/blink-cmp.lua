return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = 'InsertEnter',

    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        lazy = true,
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return nil
          end
          return 'make install_jsregexp'
        end)(),
        opts = {},
      },
      { 'folke/lazydev.nvim', ft = 'lua' },
    },

    -- 🔥 Important: pre-warm blink (and snippets) once after first real file opens
    init = function()
      vim.api.nvim_create_autocmd('BufReadPost', {
        group = vim.api.nvim_create_augroup('blink-warmup-once', { clear = true }),
        once = true,
        callback = function(ev)
          if vim.bo[ev.buf].buftype ~= '' then
            return
          end
          vim.schedule(function()
            pcall(require, 'blink.cmp')
            pcall(require, 'luasnip')
          end)
        end,
      })
    end,

    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      signature = { enabled = true },
    },
  },
}
