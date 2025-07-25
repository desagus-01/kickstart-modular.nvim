local M = {}

function M.move_completed_todos()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local new_lines = {}
  local completed_lines = {}
  local in_todo_block = false

  for _, line in ipairs(lines) do
    if line:match '^> %[%!TODO%]' then
      in_todo_block = true
      table.insert(new_lines, line)
    elseif line:match '^> %[%!' then
      in_todo_block = false
      table.insert(new_lines, line)
    elseif in_todo_block then
      -- strip leading > and whitespace before checking for completed todo
      local cleaned = line:gsub('^%s*>%s*', '')
      if cleaned:match '^%- %[X%]' then
        table.insert(completed_lines, cleaned)
      else
        table.insert(new_lines, line)
      end
    else
      table.insert(new_lines, line)
    end
  end

  -- Insert completed tasks into ## Completed section or create one
  local inserted = false
  local final_lines = {}

  for i, line in ipairs(new_lines) do
    table.insert(final_lines, line)
    if not inserted and line:match '^## Completed' then
      inserted = true
      for _, c in ipairs(completed_lines) do
        table.insert(final_lines, c)
      end
    end
  end

  if not inserted then
    table.insert(final_lines, '')
    table.insert(final_lines, '## Completed')
    for _, c in ipairs(completed_lines) do
      table.insert(final_lines, c)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, final_lines)
end

return M
