return {
  'hat0uma/csvview.nvim',
  ---@module "csvview"
  ---@type CsvView.Options
  opts = {
    parser = {
      comments = { '#', '//' },
    },
    view = {
      display_mode = 'border',
    },
    keymaps = {
      -- Text objects for selecting fields
      textobject_field_inner = { 'if', mode = { 'o', 'x' } },
      textobject_field_outer = { 'af', mode = { 'o', 'x' } },

      -- Excel-like navigation
      jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
      jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
      jump_next_row = { '<Enter>', mode = { 'n', 'v' } },
      jump_prev_row = { '<S-Enter>', mode = { 'n', 'v' } },
    },
  },
  cmd = { 'CsvViewEnable', 'CsvViewDisable', 'CsvViewToggle', 'CsvViewInfo' },

  init = function()
    local group = vim.api.nvim_create_augroup('CsvViewAutoEnable', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      group = group,
      pattern = '*.csv',
      callback = function()
        vim.schedule(function()
          vim.cmd 'CsvViewEnable'
        end)
      end,
    })
  end,
}
