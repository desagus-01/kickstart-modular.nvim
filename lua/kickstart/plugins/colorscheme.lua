return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    config = function()
      require('kanagawa').setup {
        theme = 'wave',
        background = {
          dark = 'wave',
        },
        overrides = function(colors)
          return {
            LineNr = { fg = '#FFFFFF' }, -- White line numbers
          }
        end,
      }
      vim.cmd.colorscheme 'kanagawa'
    end,
  },
}
