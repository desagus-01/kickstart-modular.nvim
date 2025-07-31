return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      formats = {
        key = function(item)
          return { { '[', hl = 'special' }, { item.key, hl = 'key' }, { ']', hl = 'special' } }
        end,
      },
      sections = {
        { section = 'terminal', cmd = 'fortune -s | cowsay', hl = 'header', padding = 3, indent = 8 },
        { title = 'Bookmarks', padding = 1 },
        { section = 'keys', padding = 1 },
        { title = 'Recent Files ', file = vim.fn.fnamemodify('.', ':~'), padding = 1 },
        { section = 'recent_files', cwd = true, limit = 8, padding = 1 },
        { title = 'Sessions', padding = 1 },
        { section = 'projects', padding = 1 },
        { title = 'Git Status', icon = ' ', padding = 1 },
        { section = 'terminal', cmd = 'git --no-pager diff --stat -B -M -C', padding = 1 },
      },
    },
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true, -- inline if terminal supports placeholders
        float = true, -- fallback float when placeholders are not available
        max_width = 80,
        max_height = 40,

        -- Hide the raw markdown link while the picture is visible
        conceal = function(lang, type)
          return type == 'image' -- still show $$math$$ blocks
        end,
      },
    },
    input = { enabled = true },
    terminal = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    rename = { enabled = true },
    words = { enabled = true },
  },
}
