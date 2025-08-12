return {
  'olimorris/codecompanion.nvim',
  opts = {
    provider = 'telescope',
    strategies = {
      chat = { adapter = 'qwen3' },
      inline = { adapter = 'qwen3' },
      cmd = { adapter = 'qwen3' },
    },
    adapters = {
      qwen3 = function()
        return require('codecompanion.adapters').extend('ollama', {
          name = 'qwen2.5-coder (local)',
          opts = {
            vision = false,
            stream = true,
          },
          schema = {
            model = {
              -- 2) Must match `ollama list`
              default = 'qwen2.5-coder:32b',
            },
            -- optional but nice:
            keep_alive = { default = '5m' },
          },
        })
      end,
    },
  },
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
}
