return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 3000,
            quiet = false, -- not recommended to change
            lsp_format = 'fallback', -- not recommended to change
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        terraform = { 'terraform_fmt' },
        tf = { 'terraform_fmt' },
        ['terraform_vars'] = { 'terraform_fmt' },
        python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
        fish = { 'fish_indent' },
        cpp = { 'clang-format' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
