return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        auto_integrations = true,
        highlight_overrides = {
          all = function(colors)
            return {
              LineNr = { fg = colors.subtext1 }, -- 👈 subtle + visible
              CursorLineNr = { fg = colors.lavender, bold = true },
            }
          end,
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
