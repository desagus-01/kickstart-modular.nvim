return {
  'alex35mil/pi.nvim',
  -- commit = '0f9f015433404da949c2e8388842c1449e88f793',
  dependencies = { 'HakonHarnes/img-clip.nvim' },
  opts = {
    -- The installed GitHub Copilot subscription already exposes both models.
    -- `exact=true` picks the first provider match (Copilot precedes OpenAI).
    models = {
      { match = 'gpt-5.3-codex', exact = true },
      { match = 'gpt-5.4-mini', exact = true },
      { match = 'claude-sonnet-5.5', exact = true },
    },
    layout = {
      default = 'side',
      side = { position = 'right', width = 84 },
    },
    attention = {
      auto_open_on_prompt_focus = true,
      notify_on_completion = true,
    },
    diff = {
      keymap_hints = 'dialog',
    },
  },
  config = function(_, opts)
    require('pi').setup(opts)

    local pi = require 'pi'
    local map = function(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, rhs, { silent = true, desc = desc })
    end

    local severity_name = {
      [vim.diagnostic.severity.ERROR] = 'ERROR',
      [vim.diagnostic.severity.WARN] = 'WARN',
      [vim.diagnostic.severity.INFO] = 'INFO',
      [vim.diagnostic.severity.HINT] = 'HINT',
    }

    local function format_diag_entry(diag)
      local sev = severity_name[diag.severity] or 'UNKNOWN'
      local lnum = (diag.lnum or 0) + 1
      local col = (diag.col or 0) + 1
      local source = diag.source and (' [' .. diag.source .. ']') or ''
      local code = diag.code and (' (' .. tostring(diag.code) .. ')') or ''
      local msg = (diag.message or ''):gsub('%s+', ' ')
      return string.format('- %s L%d:C%d%s%s %s', sev, lnum, col, source, code, msg)
    end

    local function insert_into_pi_prompt(text)
      if not pi.is_visible() then
        pi.show { layout = 'side' }
      end
      pi.focus_chat_prompt()

      local lines = vim.split(text, '\n', { plain = true })
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
      vim.api.nvim_win_set_cursor(0, { row + #lines - 1, #lines[#lines] })
    end

    local function send_current_buffer_diagnostics_to_pi()
      local bufnr = vim.api.nvim_get_current_buf()
      local abs_path = vim.api.nvim_buf_get_name(bufnr)
      if abs_path == '' then
        vim.notify('Save this buffer first so Pi can mention it by path.', vim.log.levels.WARN)
        return
      end

      local rel_path = vim.fn.fnamemodify(abs_path, ':.')
      local diagnostics = vim.diagnostic.get(bufnr)
      table.sort(diagnostics, function(a, b)
        if a.severity ~= b.severity then
          return (a.severity or 99) < (b.severity or 99)
        end
        if a.lnum ~= b.lnum then
          return (a.lnum or 0) < (b.lnum or 0)
        end
        return (a.col or 0) < (b.col or 0)
      end)

      local max_items = 40
      local lines = {}
      for i, diag in ipairs(diagnostics) do
        if i > max_items then
          lines[#lines + 1] = string.format('- ... %d more diagnostics omitted', #diagnostics - max_items)
          break
        end
        lines[#lines + 1] = format_diag_entry(diag)
      end

      local prompt
      if #lines == 0 then
        prompt = table.concat({
          string.format('Please do a quick code health check for @%s.', rel_path),
          'Neovim reports no current diagnostics in this buffer.',
        }, '\n')
      else
        prompt = table.concat({
          string.format('Please help fix diagnostics in @%s.', rel_path),
          string.format('Neovim diagnostics (%d):', #diagnostics),
          table.concat(lines, '\n'),
          'Please propose a minimal patch and explain the root cause briefly.',
        }, '\n')
      end

      insert_into_pi_prompt(prompt)
    end

    vim.api.nvim_create_user_command('PiSendDiagnostics', send_current_buffer_diagnostics_to_pi, {
      desc = 'Insert current buffer diagnostics into Pi prompt',
    })

    -- Keep Pi distinct from <leader>c (CodeCompanion) and <leader>p
    -- (existing Python/Quench workflows).
    map({ 'n', 'v' }, '<leader>aa', function()
      if pi.is_visible() then
        pi.toggle_chat()
      else
        pi.show { layout = 'side' }
      end
    end, 'Pi: toggle chat')
    map({ 'n', 'v' }, '<leader>ac', '<cmd>PiContinue<CR>', 'Pi: continue latest session')
    map({ 'n', 'v' }, '<leader>ar', '<cmd>PiResume<CR>', 'Pi: choose a session')
    map('n', '<leader>af', '<cmd>PiSendMention<CR>', 'Pi: add current file context')
    map('v', '<leader>as', '<cmd>PiSendMention<CR>', 'Pi: add selected lines as context')
    map('n', '<leader>ad', '<cmd>PiSendDiagnostics<CR>', 'Pi: add current buffer diagnostics')
    map('n', '<leader>am', '<cmd>PiSelectModel<CR>', 'Pi: choose model')
    map('n', '<leader>aM', '<cmd>PiSelectModelAll<CR>', 'Pi: choose any model')
    map('n', '<leader>at', '<cmd>PiSelectThinking<CR>', 'Pi: choose thinking level')
    map('n', '<leader>ax', '<cmd>PiAbort<CR>', 'Pi: stop current turn')
    map('n', '<leader>al', '<cmd>PiToggleLayout<CR>', 'Pi: toggle layout')
    map('n', '<leader>av', '<cmd>PiPasteImage<CR>', 'Pi: attach clipboard image')

    -- Refresh files changed by Pi while protecting modified buffers. `:checktime`
    -- asks before reloading a buffer with unsaved local edits.
    vim.opt.autoread = true
    vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
      group = vim.api.nvim_create_augroup('pi-buffer-refresh', { clear = true }),
      callback = function()
        vim.cmd 'checktime'
      end,
      desc = 'Refresh unchanged buffers after external edits (including Pi)',
    })
  end,
}
