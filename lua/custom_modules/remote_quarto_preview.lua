-- Used only by the laptop's gq SSH helper. Keep preview on the remote loopback
-- interface; the laptop browser reaches it through SSH local forwarding.
local M = {}

function M.setup()
  local port = tonumber(vim.env.QUARTO_REMOTE_PREVIEW_PORT)
  if not port or port < 1 or port > 65535 then
    return
  end

  local function close_preview(buf)
    local preview_buf = vim.b[buf].gq_preview_buf
    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
      vim.api.nvim_buf_delete(preview_buf, { force = true })
    end
    vim.b[buf].gq_preview_buf = nil
  end

  vim.keymap.set('n', '<leader>Qp', function()
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].filetype ~= 'quarto' or not file:match '%.qmd$' then
      vim.notify('Open a .qmd file before starting preview.', vim.log.levels.WARN)
      return
    end

    local existing = vim.b[buf].gq_preview_buf
    if existing and vim.api.nvim_buf_is_valid(existing) then
      local job = vim.b[existing].terminal_job_id
      if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
        vim.notify('Quarto preview is already running; save to refresh it.', vim.log.levels.INFO)
        return
      end
      close_preview(buf)
    end

    if vim.bo[buf].modified then
      vim.cmd 'write'
    end

    local doc_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd 'tabnew'
    local preview_buf = vim.api.nvim_get_current_buf()
    local ok, err = pcall(vim.fn.termopen, {
      'quarto', 'preview', file, '--no-browser', '--host', '127.0.0.1', '--port', tostring(port),
    }, { cwd = vim.fn.fnamemodify(file, ':h') })
    if not ok then
      vim.cmd 'tabclose'
      vim.notify('Cannot start Quarto preview: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.api.nvim_set_current_tabpage(doc_tab)
    vim.b[buf].gq_preview_buf = preview_buf
    vim.api.nvim_create_autocmd('BufWipeout', {
      buffer = buf,
      once = true,
      callback = function()
        close_preview(buf)
      end,
    })
  end, { desc = 'Quarto: preview current file on laptop' })

  vim.keymap.set('n', '<leader>Qq', function()
    close_preview(vim.api.nvim_get_current_buf())
  end, { desc = 'Quarto: close laptop preview' })

  -- The preview watches input files; saving replaces the plugin's manual
  -- /quarto-render/ refresh request, which is not needed in this workflow.
  vim.keymap.set('n', '<leader>Qu', '<cmd>write<CR>', { desc = 'Quarto: save and refresh laptop preview' })
end

return M
