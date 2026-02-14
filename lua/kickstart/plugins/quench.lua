return {
  'ryan-ressmeyer/quench.nvim',
  ft = 'python',

  init = function()
    vim.g.quench_nvim_web_server_host = '127.0.0.1'
    vim.g.quench_nvim_web_server_port = 8765
    vim.g.quench_nvim_autostart_server = false
  end,

  config = function()
    local group = vim.api.nvim_create_augroup('QuenchPythonKeys', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
      group = group,
      pattern = 'python',
      callback = function()
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            noremap = true,
            silent = true,
            buffer = true,
            desc = desc,
          })
        end

        map('n', '<leader>pq', '<cmd>QuenchResetKernel<CR>', 'Reset Kernel')
        map('n', '<leader>pk', '<cmd>QuenchSelectKernel<CR>', 'Select kernel')
        map('n', '<leader>pa', '<cmd>QuenchRunAll<CR>', 'Run All Cells')
        map('n', '<leader>pb', '<cmd>QuenchRunBelow<CR>', 'Run Cells below') -- fixed
        map('n', '<leader>pc', function()
          vim.api.nvim_put({ '# %%' }, 'l', true, true)
        end, 'Insert cell marker')
        map('n', '<leader>po', '<cmd>QuenchOpen<CR>', 'Open Quench UI')
        map('n', '<leader>pr', '<cmd>QuenchRunCell<CR>', 'Run current cell')
        map('v', '<leader>r', ':QuenchRunSelection<CR>', 'Run selected code')
      end,
    })
  end,
}
