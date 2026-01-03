-- lua/utils/floatterm.lua (but now Snacks-powered)
local M = {}

function M.float_term(cmd, opts)
  opts = opts or {}

  -- Snacks expects cmd as string or list; pass through
  Snacks.terminal.open(cmd, {
    cwd = opts.cwd,
    env = opts.env,

    win = {
      position = 'float',
      border = opts.border or 'rounded',
      width = opts.width_ratio or 0.75,
      height = opts.height_ratio or 0.30,
      title = opts.title,
      title_pos = opts.title_pos or 'center',
    },

    -- Apply close keys once the buffer exists
    on_buf = function(self)
      local function close()
        if self and self.win and vim.api.nvim_win_is_valid(self.win) then
          vim.api.nvim_win_close(self.win, true)
        end
      end

      local keys = opts.close_keys or { 'q', '<Esc>' }
      for _, k in ipairs(keys) do
        vim.keymap.set('t', k, close, { buffer = self.buf, nowait = true, silent = true })
        vim.keymap.set('n', k, close, { buffer = self.buf, nowait = true, silent = true })
      end
    end,
  })

  if opts.startinsert ~= false then
    vim.cmd 'startinsert'
  end
end

return M
