return {
  {
    'echasnovski/mini.nvim',
    config = function()
      -- =====================================================
      -- mini.tabline
      -- =====================================================
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

      -- Hidden by default; toggle with <leader>tt
      -- If you want it ALWAYS visible, set this to 2.
      vim.o.showtabline = 0

      -- =====================================================
      -- Buffer helpers (cycle + smart delete)
      -- =====================================================
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

        -- Last listed buffer: delete and stop
        if #bufs <= 1 then
          require('mini.bufremove').delete(current, force == true)
          return
        end

        -- Switch away first, then delete the old one
        cycle_listed_buffers(1)
        require('mini.bufremove').delete(current, force == true)
      end

      -- Buffer cycling (Alt+, / Alt+. )
      vim.keymap.set('n', '<M-,>', function()
        cycle_listed_buffers(-1)
      end, { desc = 'Previous buffer' })

      vim.keymap.set('n', '<M-.>', function()
        cycle_listed_buffers(1)
      end, { desc = 'Next buffer' })

      -- Buffer delete (Alt+x / Alt+Shift+x)
      vim.keymap.set('n', '<M-x>', function()
        smart_delete_buffer(false)
      end, { desc = 'Delete buffer (smart)' })

      vim.keymap.set('n', '<M-X>', function()
        smart_delete_buffer(true)
      end, { desc = 'Delete buffer (smart, force)' })

      -- =====================================================
      -- Tabline highlight linking
      -- =====================================================
      local function set_tabline_hl()
        local link = function(from, to)
          vim.api.nvim_set_hl(0, from, { link = to })
        end

        link('MiniTablineVisible', 'TabLine')
        link('MiniTablineHidden', 'TabLine')
        link('MiniTablineFill', 'TabLineFill')

        link('MiniTablineModifiedVisible', 'DiffText')
        link('MiniTablineModifiedHidden', 'DiffText')

        -- Current buffer: link + emphasis (no redundant double-linking)
        vim.api.nvim_set_hl(0, 'MiniTablineCurrent', { link = 'TabLineSel', bold = true, underline = true })
        vim.api.nvim_set_hl(0, 'MiniTablineModifiedCurrent', { link = 'DiffText', bold = true, underline = true })
      end

      set_tabline_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = set_tabline_hl })

      vim.keymap.set('n', '<leader>tt', function()
        vim.o.showtabline = (vim.o.showtabline == 0) and 2 or 0
      end, { desc = 'Toggle Tabline' })

      -- =====================================================
      -- mini.bufremove
      -- =====================================================
      require('mini.bufremove').setup { silent = true }

      vim.keymap.set('n', '<leader>bd', function()
        require('mini.bufremove').delete(0, false)
      end, { desc = 'Delete buffer' })

      vim.keymap.set('n', '<leader>bD', function()
        require('mini.bufremove').delete(0, true)
      end, { desc = 'Delete buffer (force)' })

      -- =====================================================
      -- Other mini modules
      -- =====================================================
      require('mini.sessions').setup { autowrite = true }
      require('mini.diff').setup()

      require('mini.pairs').setup {
        modes = { insert = true, command = true, terminal = false },
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        skip_ts = { 'string' },
        skip_unbalanced = true,
        markdown = true,
      }

      require('mini.surround').setup()

      -- mini.ai (no LazyVim dependency)
      local ai = require 'mini.ai'
      ai.setup {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter {
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          },
          f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
          c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' },
          t = {
            '<([%p%w]-)%f[^<%w][^<>]->.-</%1>',
            '^<.->().*()</[^/]->$',
          },
          d = { '%f[%d]%d+' },
          e = {
            {
              '%u[%l%d]+%f[^%l%d]',
              '%f[%S][%l%d]+%f[^%l%d]',
              '%f[%P][%l%d]+%f[^%l%d]',
              '^[%l%d]+%f[^%l%d]',
            },
            '^().*()$',
          },
          g = ai.gen_spec.buffer,
          u = ai.gen_spec.function_call(),
          U = ai.gen_spec.function_call { name_pattern = '[%w_]' },
        },
      }

      require('mini.comment').setup()

      -- =====================================================
      -- mini.statusline
      -- =====================================================
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
