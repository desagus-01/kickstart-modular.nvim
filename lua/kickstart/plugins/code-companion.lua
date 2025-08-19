return {
  'olimorris/codecompanion.nvim',
  opts = function()
    local function get_ollama_model()
      return vim.env.OLLAMA_MODEL
    end

    if pcall(get_ollama_model) then
      Chosen = get_ollama_model()
    else
      vim.notify('No OLLAMA_MODEL ENV found, setting default model qwen3:8b', vim.log.levels.error)
      Chosen = 'qwen3:8b'
    end

    -- set special options if we're on qwen3:8b
    local special_opts = { stream = true, vision = false }
    if Chosen == 'qwen3:8b' then
      special_opts = {
        stream = true,
        vision = false,
        think = { default = false },
        -- ollama extra params for efficiency on mid range CPU (laptop)
        threads = 4,
        batch = 128,
        ctx = 4096,
      }
    end

    return {
      provider = 'telescope',
      strategies = {
        chat = { adapter = 'qwen_coder' },
        inline = { adapter = 'qwen_coder' },
        cmd = { adapter = 'qwen_coder' },
      },
      adapters = {
        qwen_coder = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'Qwen Coder (Ollama)',
            opts = special_opts,
            schema = {
              model = {
                default = Chosen,
              },
            },
          })
        end,
      },
    }
  end,
}
