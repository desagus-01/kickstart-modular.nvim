return {
  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
      'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {
      animation = true,
      insert_at_start = true,
    },
    config = function()
      require('barbar').setup()
      vim.o.showtabline = 0

      -- Toggle keymap: <leader>bh toggles the tabline
      vim.keymap.set('n', '<leader>bh', function()
        if vim.o.showtabline > 0 then
          vim.o.showtabline = 0
        else
          vim.o.showtabline = 2
        end
      end, { noremap = true, silent = true, desc = 'Toggle Barbar Tabline' })
    end,
    version = '^1.0.0',
  },
}
