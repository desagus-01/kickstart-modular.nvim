-- lua/my/todo.lua
local M = {}

---------------------------------------------------------------------
-- 1.  File-resolver helper
---------------------------------------------------------------------
local function resolve_todo_path()
  local cwd_path = vim.fn.getcwd() .. '/TODO.md' -- ./TODO.md
  local default_path = vim.fn.expand '~/dev/notes/TODO.md' -- fallback

  -- a. if cwd already has one → use it
  if vim.fn.filereadable(cwd_path) == 1 then
    return cwd_path
  end

  -- b. otherwise, ask the user
  local prompt = table.concat({
    'No TODO.md in this directory.',
    '',
    '(c) Create here',
    '(d) Use default [' .. default_path .. ']',
    '(q) Cancel',
    '',
    '> ',
  }, '\n')

  local answer = vim.fn.input(prompt, 'c') -- default = 'c'
  answer = answer:lower():sub(1, 1) -- first letter only

  if answer == 'c' then
    vim.fn.writefile({}, cwd_path) -- create empty file
    return cwd_path
  elseif answer == 'd' then
    return default_path
  else
    return nil -- user aborted
  end
end

---------------------------------------------------------------------
-- 2.  Float opener  (unchanged except for path choice)
---------------------------------------------------------------------
local ui = vim.api.nvim_list_uis()[1]
local gwidth = ui.width
local gheight = ui.height
local width = math.floor(gwidth * 0.8)
local height = math.floor(gheight * 0.8)

local buf, win

local function close_float()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.cmd.write()
    vim.api.nvim_win_close(win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

function M.open()
  local path = resolve_todo_path()
  if not path then
    return
  end -- cancelled

  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((gheight - height) / 2),
    col = math.floor((gwidth - width) / 2),
    style = 'minimal',
    border = 'rounded',
  })
  vim.cmd.edit(path)

  local opts = { buffer = buf }
  vim.keymap.set('n', 'q', close_float, opts)
  vim.keymap.set('n', '<Esc>', close_float, opts)
  vim.keymap.set('n', '<C-q>', close_float, opts)
  vim.keymap.set('n', '<leader>ot', close_float, opts)
end

---------------------------------------------------------------------
-- 3.  Quick append obeys the same resolver
---------------------------------------------------------------------
function M.append()
  local path = resolve_todo_path()
  if not path then
    return
  end -- cancelled

  local input = vim.fn.input 'Add TODO: '
  if #input == 0 then
    return
  end -- empty / Esc

  local bullet = ' - ' .. input
  vim.fn.writefile({ bullet }, path, 'a') -- append safely
  vim.notify('Added to ' .. path, vim.log.levels.INFO)
end

return M
