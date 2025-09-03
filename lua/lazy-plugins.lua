-- [[ Configure and install plugins ]]
--
require 'custom_modules.planning_index'

require('lazy').setup({

  require 'kickstart.plugins.clangd_extension',

  require 'kickstart.plugins.lazygit',

  require 'kickstart.plugins.incline',

  -- require 'kickstart.plugins.quarto',

  require 'kickstart.plugins.table_nvim',

  -- require 'kickstart.plugins.copilot',

  require 'kickstart.plugins.code-companion',

  require 'kickstart.plugins.render-markdown',

  require 'kickstart.plugins.snacks',

  require 'kickstart.plugins.barbar',

  require 'kickstart.plugins.gitsigns',

  require 'kickstart.plugins.which-key',

  require 'kickstart.plugins.telescope',

  require 'kickstart.plugins.lspconfig',

  require 'kickstart.plugins.conform',

  require 'kickstart.plugins.blink-cmp',

  require 'kickstart.plugins.colorscheme',

  require 'kickstart.plugins.todo-comments',

  require 'kickstart.plugins.mini',

  require 'kickstart.plugins.treesitter',

  require 'kickstart.plugins.debug',

  require 'kickstart.plugins.lint',

  require 'kickstart.plugins.autopairs',

  require 'kickstart.plugins.neo-tree',
}, {
  ui = {

    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.api.nvim_create_user_command('MoveToCompleted', function()
  require('custom_modules.todos_to_completed').move_to_completed()
end, {})

-- vim: ts=2 sts=2 sw=2 et
