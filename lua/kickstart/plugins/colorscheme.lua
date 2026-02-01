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

              TabLineFill = { bg = colors.mantle },
              TabLine = { bg = colors.base, fg = colors.subtext1 },
              TabLineSel = { bg = colors.surface0, fg = colors.text, bold = true },

              WinSeparator = { fg = colors.surface0 },
            }
          end,
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
