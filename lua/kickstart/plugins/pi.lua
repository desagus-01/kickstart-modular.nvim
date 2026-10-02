return {
  'alex35mil/pi.nvim',
  commit = '0f9f015433404da949c2e8388842c1449e88f793',
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

    -- Keep Pi distinct from <leader>c (CodeCompanion) and <leader>p
    -- (existing Python/Quench workflows).
    map({ 'n', 'v' }, '<leader>aa', function()
      pi.show { layout = 'side' }
    end, 'Pi: open/focus active session')
    map('n', '<leader>ah', function()
      if pi.is_visible() then
        pi.toggle_chat()
      end
    end, 'Pi: hide chat (keep session running)')
    map({ 'n', 'v' }, '<leader>ac', '<cmd>PiContinue<CR>', 'Pi: continue latest session')
    map({ 'n', 'v' }, '<leader>ar', '<cmd>PiResume<CR>', 'Pi: choose a session')
    map('n', '<leader>af', '<cmd>PiSendMention<CR>', 'Pi: add current file context')
    map('v', '<leader>as', '<cmd>PiSendMention<CR>', 'Pi: add selected lines as context')
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
