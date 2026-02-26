return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      local filetypes = {
        'bash',
        'c',
        'cpp',
        'diff',
        'hcl',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'latex',
        'rust',
        'terraform',
        'vim',
        'vimdoc',
        'zig',
      }

      vim.api.nvim_create_user_command('TSEnsure', function()
        require('nvim-treesitter').install(filetypes)
      end, {})

      vim.api.nvim_create_autocmd('FileType', {
        pattern = filetypes,
        callback = function(args)
          vim.treesitter.start(args.buf)
        end,
      })
    end,
  },
}
