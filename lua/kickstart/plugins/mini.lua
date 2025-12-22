return {
  {
    'echasnovski/mini.nvim',
    config = function()
      -- TABLINE
      local tabline = require 'mini.tabline'
      tabline.setup {
        show_icons = true,
        format = function(buf_id, label)
          local s = MiniTabline.default_format(buf_id, label)
          if vim.bo[buf_id].modified then
            s = s .. ' ●'
          end
          return s .. '│'
        end,
      }
      vim.o.showtabline = 0 --default closed
      local function set_tabline_hl()
        local link = function(from, to)
          vim.api.nvim_set_hl(0, from, { link = to })
        end

        link('MiniTablineCurrent', 'TabLineSel')
        link('MiniTablineVisible', 'TabLine')
        link('MiniTablineHidden', 'TabLine')
        link('MiniTablineFill', 'TabLineFill')

        link('MiniTablineModifiedCurrent', 'DiffText')
        link('MiniTablineModifiedVisible', 'DiffText')
        link('MiniTablineModifiedHidden', 'DiffText')

        vim.api.nvim_set_hl(0, 'MiniTablineCurrent', { link = 'TabLineSel', bold = true, underline = true })
      end

      set_tabline_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = set_tabline_hl })

      vim.keymap.set('n', '<leader>tt', function()
        vim.o.showtabline = (vim.o.showtabline == 0) and 2 or 0
      end, { desc = 'Toggle Tabline' })

      -- BUFREMOVE
      require('mini.bufremove').setup { silent = true }
      vim.keymap.set('n', '<leader>bd', function()
        require('mini.bufremove').delete(0, false)
      end, { desc = 'Delete buffer' })

      vim.keymap.set('n', '<leader>bD', function()
        require('mini.bufremove').delete(0, true)
      end, { desc = 'Delete buffer (force)' })

      require('mini.sessions').setup { autowrite = true }
      require('mini.diff').setup()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.comment').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
