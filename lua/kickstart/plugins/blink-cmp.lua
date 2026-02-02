return {
  { -- Autocompletion
    'saghen/blink.cmp',
    version = '1.*',

    -- Load when you actually start typing (big startup win)
    event = 'InsertEnter',

    dependencies = {
      { -- Snippet Engine
        'L3MON4D3/LuaSnip',
        version = '2.*',
        -- LuaSnip is only needed when blink loads (InsertEnter), so it won't hit startup anymore
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return nil
          end
          return 'make install_jsregexp'
        end)(),
        opts = {},
        dependencies = {
          -- {
          --   "rafamadriz/friendly-snippets",
          --   config = function()
          --     require("luasnip.loaders.from_vscode").lazy_load()
          --   end,
          -- },
        },
      },

      -- lazydev is only really useful for Lua buffers
      { 'folke/lazydev.nvim', ft = 'lua', dependencies = { 'neovim/nvim-lspconfig' } },
    },

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
