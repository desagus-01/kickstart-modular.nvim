return {
  'olimorris/codecompanion.nvim',
  opts = function()
    -- Pick model from env, with a safe fallback
    local chosen_model = vim.env.OLLAMA_MODEL or 'qwen2.5-coder:7b'
    if not vim.env.OLLAMA_MODEL then
      vim.notify('No OLLAMA_MODEL env found; using default qwen2.5-coder:7b', vim.log.levels.WARN)
    end

    -- Base opts for this adapter
    local adapter_opts = {
      stream = true,
      vision = false,
    }

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
