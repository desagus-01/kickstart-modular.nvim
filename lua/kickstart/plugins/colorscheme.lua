return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha',
        auto_integrations = true,
        highlight_overrides = {
          all = function(colors)
            return {
              LineNr = { fg = colors.subtext1 },
              CursorLineNr = { fg = colors.pink, bold = true, italic = true },
              CursorLine = { bg = colors.surface0 },
            }
          end,
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
