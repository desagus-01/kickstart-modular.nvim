return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    latex = { enabled = false },
    completions = {
      lsp = {
        enabled = true,
      },
      blink = { enabled = true },
    },
  },
  ft = { 'markdown', 'codecompanion', 'quarto' },
}
