---@type vim.lsp.Config
return {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders',
    '--fallback-style=llvm',
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  root_markers = {
    'compile_commands.json',
    'compile_flags.txt',
    'Makefile',
    'meson.build',
    'build.ninja',
    '.git',
  },
  capabilities = {
    offsetEncoding = { 'utf-16' },
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
  settings = {
    clangd = {
      InlayHints = {
        Enabled = true,
        ParameterNames = true,
        DeducedTypes = true,
        Designators = true,
      },
    },
  },
}
