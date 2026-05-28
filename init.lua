-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Make window separators easier to see
vim.opt.fillchars = {
  eob = ' ', -- Remove annoying squigglies
  vert = '│',
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vertleft = '┫',
  vertright = '┣',
  verthoriz = '╋',
}

local function set_window_separator_highlight()
  vim.api.nvim_set_hl(0, 'WinSeparator', {
    fg = '#89b4fa',
    bg = 'NONE',
    bold = true,
  })

  -- Fallback for older themes / older Neovim versions
  vim.api.nvim_set_hl(0, 'VertSplit', {
    fg = '#89b4fa',
    bg = 'NONE',
    bold = true,
  })
end

set_window_separator_highlight()

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = set_window_separator_highlight,
})

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Add Mason bin to PATH so native vim.lsp can find installed servers
vim.env.PATH = vim.fn.stdpath 'data' .. '/mason/bin:' .. vim.env.PATH

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

-- [[ LSP configuration (0.12 native) ]]
require 'lsp'
