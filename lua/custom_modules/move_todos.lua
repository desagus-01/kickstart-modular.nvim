local M = {}

-- Detect whether a line marks the start of a TODO block
local function is_in_todo_block(line)
  if line:match '^> %[%!TODO%]' then
    return true
  elseif line:match '^> %[%!' then
    return false
  end
  return nil
end

-- Detect whether a line is a completed task within a TODO block
local function is_completed_task(line)
  return line:match '^%s*>%s*%- %[X%]'
end

-- Classify a line based on the current state (inside a TODO block or not)
local function classify_line(line, state)
  local block_state = is_in_todo_block(line)
  if block_state ~= nil then
    state.in_todo_block = block_state
    return 'todo_header', line
  end

  if state.in_todo_block then
    if is_completed_task(line) then
      return 'completed_task', line
    else
      return 'todo_task', line
    end
  end

  return 'other', line
end

-- Loop through all lines and partition into other_lines and completed_lines
local function partition_lines(lines)
  local state = { in_todo_block = false }
  local other_lines, completed_lines = {}, {}

  for _, line in ipairs(lines) do
    local kind, content = classify_line(line, state)

    if kind == 'completed_task' then
      table.insert(completed_lines, content)
    else
      table.insert(other_lines, content)
    end
  end

  return other_lines, completed_lines
end

-- Insert completed tasks into the `## Completed` section or create one if not found
local function inject_completed_tasks(other_lines, completed_lines)
  local final_lines, inserted = {}, false

  for _, line in ipairs(other_lines) do
    table.insert(final_lines, line)

    if not inserted and line:match '^## Completed' then
      inserted = true
      vim.list_extend(final_lines, completed_lines)
    end
  end

  if not inserted then
    table.insert(final_lines, '')
    table.insert(final_lines, '## Completed')
    vim.list_extend(final_lines, completed_lines)
  end

  return final_lines
end

-- Main entrypoint: reorganize the buffer to move completed TODOs to the "## Completed" section
function M.move_completed_todos()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local other_lines, completed_lines = partition_lines(lines)
  local final_lines = inject_completed_tasks(other_lines, completed_lines)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, final_lines)
end

return M
