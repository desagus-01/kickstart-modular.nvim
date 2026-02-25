return {
  'olimorris/codecompanion.nvim',
  opts = function()
    -- Pick model from env, with a safe fallback
    local chosen_model = vim.env.OLLAMA_MODEL
    if not vim.env.OLLAMA_MODEL then
      vim.notify('No OLLAMA_MODEL env found', vim.log.levels.WARN)
    end

    -- Base opts for this adapter
    local adapter_opts = {
      stream = true,
      vision = false,
    }

    local function map(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, rhs, { noremap = true, silent = true, desc = desc })
    end

    -- Chat toggle
    map('n', '<leader>cc', '<cmd>CodeCompanionChat Toggle<CR>', 'CodeCompanion: Toggle chat')

    -- Inline assistant:
    -- Normal mode can stay <cmd>...
    map('n', '<leader>ca', '<cmd>CodeCompanion<CR>', 'CodeCompanion: Inline assistant')

    -- Visual mode MUST use a range (:'<,'>) or selection context won’t apply properly
    map('v', '<leader>ca', ":'<,'>CodeCompanion<CR>", 'CodeCompanion: Inline assistant (selection)')

    -- Command mode helper
    map('n', '<leader>cm', '<cmd>CodeCompanionCmd<CR>', 'CodeCompanion: Command mode')

    return {
      provider = 'telescope',
      strategies = {
        chat = {
          adapter = 'qwen_coder',
          roles = {
            user = 'Gus',
            llm = chosen_model,
          },
        },
        inline = { adapter = 'qwen_coder' },
        cmd = { adapter = 'qwen_coder' },
      },
      adapters = {
        http = {
          qwen_coder = function()
            return require('codecompanion.adapters').extend('ollama', {
              name = 'Qwen Coder (Ollama)',
              opts = adapter_opts,
              schema = {
                model = {
                  default = chosen_model,
                },
                think = {
                  default = false,
                },
                keep_alive = {
                  default = '5m',
                },
              },
            })
          end,
        },
      },
    }
  end,
}
