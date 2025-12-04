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
    -- FILESYSTEM OPTIONS
    opts.filesystem = opts.filesystem or {}
    opts.filesystem.filtered_items = {
      visible = false,
      hide_gitignored = true,
      hide_dotfiles = false,
      hide_by_name = {
        '.github',
      },
      never_show = { '.git' },
    }

    opts.filesystem.window = opts.filesystem.window or {}
    opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}

    -- existing mapping
    opts.filesystem.window.mappings['\\'] = 'close_window'

    -- add "o" mapping to our custom command
    opts.filesystem.window.mappings['o'] = 'system_open'

    -- CUSTOM COMMANDS
    opts.commands = opts.commands or {}
    opts.commands.system_open = function(state)
      local node = state.tree:get_node()
      local path = node:get_id()

      -- macOS: open file in default application
      if vim.fn.has 'macunix' == 1 then
        vim.fn.jobstart({ 'open', path }, { detach = true })

      -- Linux: open file in default application
      elseif vim.fn.has 'unix' == 1 then
        vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
      end
    end

    -- RENAME HANDLER
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
