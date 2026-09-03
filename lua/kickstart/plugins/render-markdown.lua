return {
  'MeanderingProgrammer/render-markdown.nvim',

  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'echasnovski/mini.nvim',
  },

  ft = {
    'markdown',
    'codecompanion',
    'quarto',
  },

  -- ========================================================================
  -- KEYMAP
  -- ========================================================================
  --
  -- Space Q v
  --
  -- Toggle pretty/raw rendering for the current document.
  --
  -- Normally you should NOT need this because rendering automatically
  -- disappears while you're in Insert mode.
  -- ========================================================================

  keys = {
    {
      '<leader>Qv',
      '<cmd>RenderMarkdown buf_toggle<cr>',
      desc = 'Quarto: toggle rendered view',
      ft = { 'markdown', 'quarto' },
    },
  },

  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    render_modes = {
      'n',
      'c',
      't',
    },

    anti_conceal = {
      enabled = true,
    },

    heading = {
      enabled = true,
      position = 'inline',
      sign = false,
    },

    code = {
      enabled = true,
      conceal_delimiters = true,
      language = true,
      language_icon = true,
      language_name = true,
      width = 'full',
      left_pad = 1,
      right_pad = 1,
      border = 'thin',
    },

    pipe_table = {
      enabled = true,
    },

    latex = {
      enabled = true,
    },
  },
}
