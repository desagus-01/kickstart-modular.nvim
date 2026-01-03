local M = {}

local function make_float(opts)
  opts = opts or {}
  local border = opts.border or 'rounded'
  local title = opts.title
  local width_ratio = opts.width_ratio or 0.75
  local height_ratio = opts.height_ratio or 0.30
  local focus = opts.focus ~= false

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * width_ratio)
  local height = math.floor(ui.height * height_ratio)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = border,
  }

  if title then
    win_opts.title = title
    win_opts.title_pos = opts.title_pos or 'center'
  end

  local win = vim.api.nvim_open_win(buf, focus, win_opts)
  return buf, win
end

function M.float_term(cmd, opts)
  opts = opts or {}

  local term_cmd
  if type(cmd) == 'string' then
    term_cmd = { 'sh', '-c', cmd }
  else
    term_cmd = cmd
  end

  local buf, win = make_float(opts)

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local cwd = opts.cwd
  if not cwd or cwd == '' then
    cwd = vim.fs.root(0, { 'pyproject.toml', '.git' }) or vim.fn.expand '%:p:h'
  end

  local job_id = vim.fn.termopen(term_cmd, {
    cwd = cwd, -- ✅ use computed cwd
    env = opts.env,
    on_exit = function(_, code, _)
      if opts.on_exit then
        vim.schedule(function()
          opts.on_exit(code, { buf = buf, win = win, close = close })
        end)
      end

      if opts.auto_close and code == 0 then
        vim.schedule(close)
      end
    end,
  })

  local close_keys = opts.close_keys or { 'q', '<Esc>' }
  for _, k in ipairs(close_keys) do
    vim.keymap.set('t', k, close, { buffer = buf, nowait = true, silent = true })
    vim.keymap.set('n', k, close, { buffer = buf, nowait = true, silent = true })
  end

  if opts.startinsert ~= false then
    vim.cmd 'startinsert'
  end

  return {
    buf = buf,
    win = win,
    job_id = job_id,
    close = close,
  }
end

return M
