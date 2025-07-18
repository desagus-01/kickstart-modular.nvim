-- A tiny helper module that exports two public functions:
--   M.open()  – show the floating TODO list
--   M.append() – prompt & append a new bullet

local M = {}

-- ----------- internal state (kept local) -----------------
local ui = vim.api.nvim_list_uis()[1] -- cache on first load
local gwidth = ui.width
local gheight = ui.height
local width = math.floor(gwidth * 0.8)
local height = math.floor(gheight * 0.8)

local buf, win -- will hold handles across calls

-- ---------------------------------------------------------
local function close_float()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.cmd.write() -- save
    vim.api.nvim_win_close(win, true) -- force close
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

function M.open()
  -- Open TODO.md in a centred floating window
  buf = vim.api.nvim_create_buf(false, true) -- scratch
  win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((gheight - height) / 2),
    col = math.floor((gwidth - width) / 2),
    style = 'minimal',
    border = 'rounded',
  })
  vim.cmd.edit(vim.fn.expand '~/dev/notes/TODO.md')

  -- buffer-local quit keys
  local opts = { buffer = buf }
  vim.keymap.set('n', 'q', close_float, opts)
  vim.keymap.set('n', '<Esc>', close_float, opts)
  vim.keymap.set('n', '<C-q>', close_float, opts)
  vim.keymap.set('n', '<leader>ot', close_float, opts)
end

function M.append()
  local input = vim.fn.input 'Add TODO: '
  if #input == 0 then
    return
  end -- cancelled
  local bullet = ' - ' .. input
  -- safer than shelling out:
  vim.fn.writefile({ bullet }, vim.fn.expand '~/dev/notes/TODO.md', 'a')
end

return M
