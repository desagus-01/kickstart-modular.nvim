-- Snacks terminal
vim.keymap.set({ 'n', 't' }, '<C-`>', function()
  require('snacks.terminal').toggle()
end, { desc = 'Toggle Snacks terminal' })

vim.keymap.set('n', '<leader>qg', function()
  vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
    if not msg or msg == '' then
      return
    end
    msg = msg:gsub('"', '\\"')

    local cmd = 'git add . && git commit -m "' .. msg .. '" && git push'
    vim.cmd('botright split | resize 12 | terminal sh -c ' .. vim.fn.shellescape(cmd))
    vim.cmd 'startinsert'
  end)
end, { desc = 'Quick Git Commit Push' })

-- quick save, quite and quit and save
vim.keymap.set('n', '<leader>qw', function()
  local file_name = vim.fn.expand '%:t'
  vim.cmd 'w'
  vim.notify(string.format('Saved File: %s ✔️', file_name))
end, { desc = 'Quick Save', silent = true })
vim.keymap.set('n', '<leader>qq', function()
  vim.cmd 'q'
end, { desc = 'Quick Quit', silent = true })
vim.keymap.set('n', '<leader>qe', function()
  vim.cmd 'x'
end, { desc = 'Quick Quit and Save', silent = true })

-- Add new line
vim.keymap.set('n', '<CR>', 'm`o<Esc>``')
vim.keymap.set('n', '<S-CR>', 'm`O<Esc>``')

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>qd', vim.diagnostic.setloclist, { desc = 'Quick Diagnostics' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
vim.keymap.set({ 'n', 't' }, '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set({ 'n', 't' }, '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set({ 'n', 't' }, '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set({ 'n', 't' }, '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Making splits and resizing easier
vim.keymap.set('n', '<C-x>', ':vsplit<CR>', { desc = 'Vertical split of window' })
vim.keymap.set('n', '<A-l>', ':vertical resize -2<CR>')
vim.keymap.set('n', '<A-h>', ':vertical resize +2<CR>')

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Custom keybinds for plugins
-- Code companion
-- vim.keymap.set({ 'n', 'v' }, '<C-a>', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true })
-- vim.keymap.set({ 'n', 'v' }, '<LocalLeader>a', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true })
-- vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true })
--
-- -- Expand 'cc' into 'CodeCompanion' in the command line
-- vim.cmd [[cab cc CodeCompanion]]
--
--
local todo = require -- tiny alias so we don't type the full path twice

vim.keymap.set('n', '<leader>oo', function()
  todo('custom_modules.floating_todo').open()
end, { desc = 'Open TODO list' })

vim.keymap.set('n', '<leader>oa', function()
  todo('custom_modules.floating_todo').append()
end, { desc = 'Add to TODO list' })

-- auto move todos in .md
local todo = require 'custom_modules.move_todos'
vim.api.nvim_create_augroup('AutoMoveTodosOnMarkdown', { clear = true })

vim.api.nvim_create_autocmd('BufWritePre', {
  group = 'AutoMoveTodosOnMarkdown',
  pattern = '*.md',
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for _, line in ipairs(lines) do
      if line:match '> %[%!TODO%]' then
        todo.move_completed_todos()
        break
      end
    end
  end,
})

-- Complete todo
vim.keymap.set('n', '<leader>xc', function()
  local line = vim.api.nvim_get_current_line()
  local new_line = line:gsub('(%s*%- %[%s*%])', ' - [X]')
  vim.api.nvim_set_current_line(new_line)
end, { desc = '[C]omplete TODO' })

-- Create todo
vim.keymap.set('n', '<leader>xa', function()
  local line = vim.api.nvim_get_current_line()
  local prefix = '> - [ ] '
  local new_line = prefix .. line
  vim.api.nvim_set_current_line(new_line)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = new_line:find '%[ %]' + 8
  vim.api.nvim_win_set_cursor(0, { row, col })
  vim.cmd 'startinsert'
end, { desc = '[A]dd TODO' })

-- yank whole doc
vim.keymap.set('n', 'yy', '<cmd>%y+<CR>', { desc = 'Yank Whole Doc' })

-- rename symbol
vim.keymap.set('n', '<leader>rp', vim.lsp.buf.rename, { desc = 'Rename in Project' })

vim.keymap.set('n', '<leader>rf', vim.lsp.buf.rename, { desc = 'Rename (LSP)' })
