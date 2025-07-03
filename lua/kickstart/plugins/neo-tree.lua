return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = function(_, opts)
    -- Add your custom window mappings
    opts.filesystem = opts.filesystem or {}
    opts.filesystem.window = opts.filesystem.window or {}
    opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}
    opts.filesystem.window.mappings['\\'] = 'close_window'

    -- Integrate your rename handler
    local events = require 'neo-tree.events'
    local function on_move(data)
      -- Replace Snacks.rename.on_rename_file with your actual rename handler
      Snacks.rename.on_rename_file(data.source, data.destination)
    end

    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
      { event = events.FILE_MOVED, handler = on_move },
      { event = events.FILE_RENAMED, handler = on_move },
    })
  end,
}
