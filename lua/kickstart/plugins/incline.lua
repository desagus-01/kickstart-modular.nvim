return {
  'b0o/incline.nvim',
  event = 'VeryLazy',
  config = function()
    local devicons = require 'nvim-web-devicons'
    local incline = require 'incline'

    local function set_mode_hl()
      local function contrast_fg(bg)
        local r = bit.rshift(bit.band(bg, 0xFF0000), 16)
        local g = bit.rshift(bit.band(bg, 0x00FF00), 8)
        local b = bit.band(bg, 0x0000FF)
        local y = (r * 299 + g * 587 + b * 114) / 1000
        return (y > 140) and 0x101010 or 0xF2F2F2
      end

      local palette = (vim.o.background == 'light')
          and {
            N = 0x3B82F6, -- blue
            I = 0x16A34A, -- green
            V = 0x7C3AED, -- purple
            R = 0xDC2626, -- red
            C = 0xD97706, -- amber
            T = 0x0891B2, -- cyan
          }
        or {
          N = 0x60A5FA, -- blue
          I = 0x34D399, -- green
          V = 0xA78BFA, -- purple
          R = 0xF87171, -- red
          C = 0xFBBF24, -- amber
          T = 0x22D3EE, -- cyan
        }

      for key, bg in pairs(palette) do
        vim.api.nvim_set_hl(0, 'InclineModeChip' .. key, {
          fg = contrast_fg(bg),
          bg = bg,
          bold = true,
        })
      end
    end
    set_mode_hl()
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('InclineModeColors', { clear = true }),
      callback = set_mode_hl,
    })

    local mode_map = {
      n = { 'N', 'InclineModeChipN' },
      no = { 'N', 'InclineModeChipN' },

      i = { 'I', 'InclineModeChipI' },
      ic = { 'I', 'InclineModeChipI' },

      v = { 'V', 'InclineModeChipV' },
      V = { 'V', 'InclineModeChipV' },
      ['\22'] = { 'V', 'InclineModeChipV' }, -- CTRL-V block

      R = { 'R', 'InclineModeChipR' },
      Rc = { 'R', 'InclineModeChipR' },
      Rv = { 'R', 'InclineModeChipR' },

      c = { 'C', 'InclineModeChipC' },
      cv = { 'C', 'InclineModeChipC' },
      ce = { 'C', 'InclineModeChipC' },

      t = { 'T', 'InclineModeChipT' },
    }

    local function mode_badge()
      local m = vim.api.nvim_get_mode().mode
      local entry = mode_map[m] or mode_map[m:sub(1, 1)] or { '?', 'Comment' }
      return entry[1], entry[2]
    end

    vim.api.nvim_create_autocmd('ModeChanged', {
      group = vim.api.nvim_create_augroup('InclineModeRefresh', { clear = true }),
      callback = function()
        incline.refresh()
      end,
    })

    incline.setup {
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
        if filename == '' then
          filename = '[No Name]'
        end

        local ft_icon, ft_color = devicons.get_icon_color(filename)

        local function get_git_diff()
          local icons = { removed = '', changed = '', added = '' }
          local signs = vim.b[props.buf].gitsigns_status_dict
          local labels = {}
          if not signs then
            return labels
          end
          for name, icon in pairs(icons) do
            if tonumber(signs[name]) and signs[name] > 0 then
              table.insert(labels, { icon .. signs[name] .. ' ', group = 'Diff' .. name })
            end
          end
          if #labels > 0 then
            table.insert(labels, { '┊ ' })
          end
          return labels
        end

        local function get_diagnostic_label()
          local icons = { error = '', warn = '', info = '', hint = '' }
          local label = {}
          for severity, icon in pairs(icons) do
            local n = #vim.diagnostic.get(props.buf, {
              severity = vim.diagnostic.severity[string.upper(severity)],
            })
            if n > 0 then
              table.insert(label, { icon .. n .. ' ', group = 'DiagnosticSign' .. severity })
            end
          end
          if #label > 0 then
            table.insert(label, { '┊ ' })
          end
          return label
        end

        local badge, badge_group = mode_badge()

        return {
          { ' ' .. badge .. ' ', group = badge_group },
          { '┊ ' },
          { get_diagnostic_label() },
          { get_git_diff() },
          { (ft_icon or '') .. ' ', guifg = ft_color, guibg = 'none' },
          { filename .. ' ', gui = vim.bo[props.buf].modified and 'bold,italic' or 'bold' },
        }
      end,
    }
  end,
}
