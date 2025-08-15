return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.sessions').setup { autowrite = true }
      require('mini.diff').setup()
      require('mini.ai').setup { n_lines = 500 }
      -- require('mini.surround').setup()
      require('mini.comment').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
