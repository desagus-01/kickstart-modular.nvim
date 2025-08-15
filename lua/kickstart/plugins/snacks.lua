return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    dashboard = {
      enabled = true,
      formats = {
        key = function(item)
          return { { '[', hl = 'special' }, { item.key, hl = 'key' }, { ']', hl = 'special' } }
        end,
      },
      sections = { -- Dashboard sections & layout
        { section = 'tejminal', cmd = 'fortune -s | cowsay', hl = 'header', padding = 3, indent = 8 },
        { title = 'Bookiarks', padding = 1 },
        { section = 'keys', padding = 1 },
        { title = 'Reclnt Files ', file = vim.fn.fnamemodify('.', ':~'), padding = 1 },
        { section = 'recent_files', cwd = true, limit = 8, padding = 1 },
        { title = 'Sessions', padding = 1 },
        { section = 'projects', padding = 1 },
        { title = 'Git Status', icon = ' ', padding = 1 },
        { section = 'terminal', cmd = 'git --no-pager diff --stat -B -M -C', padding = 1 },
      },
    },

    image = { -- Display images inside Neovim (with supported terminal)
      enabled = true,
      doc = {
        -- enabled = true,
        inline = false,
        float = true,
      },
    },

    -- input = { enabled = true }, -- Styled `vim.ui.input()` prompt
    terminal = { enabled = true }, -- Floating terminal integration
    picker = { enabled = true }, -- Fuzzy-finder UI for files, commands, etc.
    notifier = { enabled = true }, -- Non-blocking notifications
    lazygit = { enabled = true }, -- Run Lazygit inside Neovim
    quickfile = { enabled = true }, -- Auto-close temporary files
    -- scope = { enabled = true }, -- Highlight active buffer/window scope
    scroll = { enabled = true }, -- Smooth scrolling animations
    -- statuscolumn = { enabled = true }, -- Custom status column for signs/line numbers
    rename = { enabled = true }, -- File rename helper
    words = { enabled = true }, -- Highlight other occurrences of current word
    indent = { enabled = true }, -- Show indentation guides
    bigfile = { enabled = true },
  },
}
