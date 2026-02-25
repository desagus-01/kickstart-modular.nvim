-- floating quick commit/push
local floatterm = require 'utils' -- floating term helper

vim.keymap.set('n', '<leader>qg', function()
  vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
    if not msg or msg == '' then
      return
    end
    msg = msg:gsub('"', '\\"')

    local cmd = 'git add . && git commit -m "' .. msg .. '" && git push'

    floatterm.float_term(cmd, {
      title = 'Git: add + commit + push',
      auto_close = true,
      height_ratio = 0.30,
      width_ratio = 0.75,
      close_keys = { 'q', '<Esc>' },
      on_exit = function(code, ctx)
        if code ~= 0 then
          vim.notify('Git command failed (exit ' .. code .. ')', vim.log.levels.WARN)
        end
      end,
    })
  end)
end, { desc = 'Quick Git Commit Push (float)' })

-- quick runners
vim.keymap.set('n', '<leader>qR', function()
  if vim.bo.modified then
    vim.cmd 'write'
  end

  local file = vim.fn.expand '%:p'
  if file == '' then
    return
  end

  local cmd = 'uv run ' .. vim.fn.fnameescape(file)

  floatterm.float_term(cmd, {
    title = 'uv run: ' .. vim.fn.expand '%:t',
    cwd = vim.fn.expand '%:p:h',
    auto_close = false,
    close_keys = { 'q', '<Esc>' },
    width_ratio = 0.80,
    height_ratio = 0.35,
  })
end, { desc = 'Run in floating (Python only)' })

-- Run current Python file in the persistent
vim.keymap.set('n', '<leader>qr', function()
  if vim.bo.modified then
    vim.cmd 'write'
  end

  local file = vim.fn.expand '%:p'
  if file == '' then
    return
  end

  local cmd = 'uv run ' .. vim.fn.fnameescape(file)

  -- 1) Ensure the persistent terminal exists and is visible
  -- (Snacks: no cmd => bottom split terminal)
  local term, _ = Snacks.terminal.get(nil, { create = true }) -- returns terminal win object
  if term and term.show then
    term:show()
  else
    -- fallback: at least toggle it open
    Snacks.terminal.toggle()
  end

  -- 2) Find a snacks terminal buffer that has a terminal job
  local term_buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].filetype == 'snacks_terminal' and vim.b[b].terminal_job_id then
      term_buf = b
      break
    end
  end

  if not term_buf then
    vim.notify("Couldn't find Snacks terminal buffer to send command to.", vim.log.levels.ERROR)
    return
  end

  -- 3) Send the command to the terminal job
  local chan = vim.b[term_buf].terminal_job_id
  vim.api.nvim_chan_send(chan, cmd .. '\n')
end, { desc = 'Run Python (uv) in persistent Snacks terminal' })

-- Snacks terminal
vim.keymap.set({ 'n', 't' }, '<C-`>', function()
  require('snacks.terminal').toggle()
end, { desc = 'Toggle Snacks terminal' })

-- quick save, quit and quit and save
vim.keymap.set('n', '<leader>qw', function()
  local file_name = vim.fn.expand '%:t'
  vim.cmd 'w'
  vim.notify(string.format('Saved File: %s ✔️', file_name))
end, { desc = 'Quick Save', silent = true })
vim.keymap.set('n', '<leader>qq', function()
  vim.cmd 'wq'
end, { desc = 'Quick Quit Window', silent = true })
vim.keymap.set('n', '<leader>qe', function()
  vim.cmd 'qa'
end, { desc = 'Quick Quit All', silent = true })

-- Add new line
vim.keymap.set('n', '<CR>', 'm`o<Esc>``')
vim.keymap.set('n', '<S-CR>', 'm`O<Esc>``')

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Quick Diagnostic keymaps
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

-- Todos stuff
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
vim.keymap.set('n', 'Y', function()
  local view = vim.fn.winsaveview()
  vim.cmd [[silent keepjumps %y+]]
  vim.fn.winrestview(view)
end, { desc = 'Yank whole buffer to clipboard' })

vim.keymap.set('n', '<leader>rp', vim.lsp.buf.rename, { desc = 'Rename in Project' })

vim.keymap.set('n', '<leader>rf', vim.lsp.buf.rename, { desc = 'Rename (LSP)' })
