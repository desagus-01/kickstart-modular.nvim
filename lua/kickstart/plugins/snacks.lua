-- return {
--   'folke/snacks.nvim',
--   priority = 1000,
--   lazy = false,
--   ---@type snacks.Config
--   opts = {
--     bigfile = { enabled = true },
--     dashboard = {
--       enabled = true,
--       formats = {
--         key = function(item)
--           return { { '[', hl = 'special' }, { item.key, hl = 'key' }, { ']', hl = 'special' } }
--         end,
--       },
--       sections = {
--         { section = 'terminal', cmd = 'fortune -s | cowsay', hl = 'header', padding = 3, indent = 8 },
--         { title = 'Bookmarks', padding = 1 },
--         { section = 'keys', padding = 1 },
--         { title = 'Recent Files ', file = vim.fn.fnamemodify('.', ':~'), padding = 1 },
--         { section = 'recent_files', cwd = true, limit = 8, padding = 1 },
--         { title = 'Sessions', padding = 1 },
--         { section = 'projects', padding = 1 },
--         { title = 'Git Status', icon = ' ', padding = 1 },
--         { section = 'terminal', cmd = 'git --no-pager diff --stat -B -M -C', padding = 1 },
--       },
--     },
--     image = {
--       enabled = true,
--       doc = {
--         -- enabled = true,
--         inline = false, -- inline if terminal supports placeholders
--         float = true, -- fallback float when placeholders are not available
--       },
--     },
--     input = { enabled = true },
--     terminal = { enabled = true },
--     -- picker = { enabled = true },
--     notifier = { enabled = true },
--     lazygit = { enabled = true },
--     quickfile = { enabled = true },
--     scope = { enabled = true },
--     scroll = { enabled = true },
--     statuscolumn = { enabled = true },
--     rename = { enabled = true },
--     words = { enabled = true },
--     indent = { enabled = true },
--   },
-- }
--
--

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,

  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },

    -- Window-layer background: make Snacks terminal windows use Normal
    styles = {
      terminal = {
        wo = {
          winhighlight = table.concat({
            'Normal:Normal',
            'NormalNC:Normal',
            'NormalFloat:Normal',
            'FloatBorder:Normal',
            'EndOfBuffer:Normal',
            'SignColumn:Normal',
          }, ','),
          winblend = 0,
        },
      },
    },

    dashboard = {
      enabled = true,

      formats = {
        key = function(item)
          return { { '[', hl = 'special' }, { item.key, hl = 'key' }, { ']', hl = 'special' } }
        end,
      },

      preset = {
        header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
        keys = {
          {
            icon = '󰱼 ',
            key = 'f',
            desc = 'Find File',
            action = function()
              Snacks.picker.files()
            end,
          },
          { icon = '󰈔 ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
          {
            icon = '󰱼 ',
            key = 'g',
            desc = 'Find Text',
            action = function()
              Snacks.picker.grep()
            end,
          },
          {
            icon = '󱦠 ',
            key = 'r',
            desc = 'Recent Files',
            action = function()
              Snacks.picker.recent()
            end,
          },
          {
            icon = '󰒲 ',
            key = 'c',
            desc = 'Config',
            action = function()
              Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
            end,
          },
          {
            icon = '󰁯 ',
            key = 's',
            desc = 'Restore Session',
            action = function()
              require('persistence').load()
            end,
          },
          { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy' },
          { icon = '󰈆 ', key = 'q', desc = 'Quit', action = ':quitall!' },
        },
      },

      sections = {
        -- LEFT PANE
        {
          section = 'terminal',
          cmd = 'asciiquarium -t',
          height = 27,
          padding = 0,
          indent = 0,
        },

        -- RIGHT PANE
        {
          pane = 2,
          { section = 'header', padding = 1 },
          { section = 'keys', gap = 1, padding = 1 },
          { section = 'startup' },
        },
      },
    },

    terminal = { enabled = true },
    notifier = { enabled = true },
    lazygit = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    rename = { enabled = true },
    words = { enabled = true },
    indent = { enabled = true },
  },

  config = function(_, opts)
    require('snacks').setup(opts)

    local group = vim.api.nvim_create_augroup('SnacksAquariumBg', { clear = true })

    -- Cache bg per-colorscheme for efficiency
    local cached_bg ---@type string|nil

    local function hl_bg_hex(name)
      local id = vim.fn.hlID(name)
      if not id or id == 0 then
        return nil
      end
      local bg = vim.fn.synIDattr(id, 'bg#')
      if bg == nil or bg == '' or bg == 'NONE' then
        return nil
      end
      return bg
    end

    local function compute_bg()
      return hl_bg_hex 'Normal' or hl_bg_hex 'SnacksDashboardNormal' or hl_bg_hex 'NormalFloat' or hl_bg_hex 'FloatNormal'
    end

    local function get_bg()
      if cached_bg == nil then
        cached_bg = compute_bg()
      end
      return cached_bg
    end

    local function is_asciiquarium_term(bufnr)
      -- Try to identify the terminal’s command without expensive scans.
      -- Many terminals expose this via b:term_title or the channel info.
      local title = vim.b[bufnr] and vim.b[bufnr].term_title
      if type(title) == 'string' and title:find('asciiquarium', 1, true) then
        return true
      end

      -- Fallback: check channel command (still cheap, only on TermOpen)
      local chan = vim.bo[bufnr].channel
      if chan and chan ~= 0 then
        local info = vim.api.nvim_get_chan_info(chan)
        local cmd = info and info.argv
        if type(cmd) == 'table' then
          for _, part in ipairs(cmd) do
            if type(part) == 'string' and part:find('asciiquarium', 1, true) then
              return true
            end
          end
        end
      end

      return false
    end

    local function apply_palette(bufnr, bg)
      -- Only affect this terminal buffer
      vim.b[bufnr].terminal_color_0 = bg
      vim.b[bufnr].terminal_color_8 = bg

      -- Optional: if your build only respects globals, uncomment these:
      -- vim.g.terminal_color_0 = bg
      -- vim.g.terminal_color_8 = bg
    end

    vim.api.nvim_create_autocmd('TermOpen', {
      group = group,
      callback = function(ev)
        local bufnr = ev.buf
        if not is_asciiquarium_term(bufnr) then
          return
        end

        local bg = get_bg()
        if not bg then
          return
        end

        apply_palette(bufnr, bg)
      end,
    })

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = group,
      callback = function()
        cached_bg = nil
        local bg = get_bg()
        if not bg then
          return
        end

        -- Refresh only existing asciiquarium terminals
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buftype == 'terminal' and is_asciiquarium_term(b) then
            apply_palette(b, bg)
          end
        end
      end,
    })
  end,
}
