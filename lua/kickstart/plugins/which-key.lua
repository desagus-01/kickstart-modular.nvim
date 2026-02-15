return {
  {
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains

      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>q', group = '[Q]uick Actions' },
        { '<leader>o', group = 'T[O]DO' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>p', group = '󰌠 [P]ython Interactive', mode = { 'n', 'v' } },

        -- MiniSurround (Normal mode)
        { 'gS', group = 'Surround' },
        { 'gSa', desc = 'Add surrounding' },
        { 'gSd', desc = 'Delete surrounding' },
        { 'gSr', desc = 'Replace surrounding' },
        { 'gSf', desc = 'Find right surrounding' },
        { 'gSF', desc = 'Find left surrounding' },
        { 'gSh', desc = 'Highlight surrounding' },
        { 'gSn', desc = 'Update n_lines' },

        -- MiniSurround (Visual mode, mainly add)
        { 'gS', group = 'Surround', mode = 'v' },
        { 'gSa', desc = 'Add surrounding', mode = 'v' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
