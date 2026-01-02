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

      vim.o.showtabline = 0 -- default closed

      -- -----------------------------------------------------
      -- Buffer helpers (cycle + smart delete)
      -- -----------------------------------------------------
      local function get_listed_buffers()
        return vim.tbl_filter(function(b)
          return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
        end, vim.api.nvim_list_bufs())
      end

      local function cycle_listed_buffers(direction)
        local bufs = get_listed_buffers()
        if #bufs == 0 then
          return
        end

        local current = vim.api.nvim_get_current_buf()
        local idx = 1
        for i, b in ipairs(bufs) do
          if b == current then
            idx = i
            break
          end
        end

        local next_idx = ((idx - 1 + direction) % #bufs) + 1
        vim.api.nvim_set_current_buf(bufs[next_idx])
      end

      local function smart_delete_buffer(force)
        local bufs = get_listed_buffers()
        local current = vim.api.nvim_get_current_buf()

        -- If this is the last listed buffer, just delete it and stop.
        -- (Neovim will keep you in an empty buffer, which is fine.)
        if #bufs <= 1 then
          require('mini.bufremove').delete(current, force == true)
          return
        end

        -- Move first so we never end up staring at a "dead" window
        cycle_listed_buffers(1)

        -- Then delete the buffer we came from
        require('mini.bufremove').delete(current, force == true)
      end

      -- BUFFER CYCLING (Alt+, / Alt+. )
      vim.keymap.set('n', '<M-,>', function()
        cycle_listed_buffers(-1)
      end, { desc = 'Previous buffer' })

      vim.keymap.set('n', '<M-.>', function()
        cycle_listed_buffers(1)
      end, { desc = 'Next buffer' })

      -- BUFFER DELETE (Alt+x / Alt+Shift+x)
      vim.keymap.set('n', '<M-x>', function()
        smart_delete_buffer(false)
      end, { desc = 'Delete buffer (smart)' })

      vim.keymap.set('n', '<M-X>', function()
        smart_delete_buffer(true)
      end, { desc = 'Delete buffer (smart, force)' })

      -- -----------------------------------------------------
      -- Tabline highlight linking
      -- -----------------------------------------------------
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

      -- Other mini modules
      require('mini.sessions').setup { autowrite = true }
      require('mini.diff').setup()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.comment').setup()

      -- STATUSLINE
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
