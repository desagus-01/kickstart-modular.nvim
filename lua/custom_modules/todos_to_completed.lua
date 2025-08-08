local M = {}

-- === Utility Functions ===
local function expand_home(path)
  return path:gsub('^~', os.getenv 'HOME')
end

local function read_lines(path)
  local lines = {}
  local f = io.open(path, 'r')
  if f then
    for line in f:lines() do
      table.insert(lines, line)
    end
    f:close()
  end
  return lines
end

local function write_lines(path, lines)
  local f = assert(io.open(path, 'w'))
  for _, line in ipairs(lines) do
    f:write(line .. '\n')
  end
  f:close()
end

local function is_completed_heading(line)
  return line:match '^#+%s*Completed' ~= nil
end

local function is_blank_line(line)
  return line:match '^%s*$' ~= nil
end

local function extract_completed_tasks(lines)
  local state = { completed_task = false }
  local collected = {}

  for _, line in ipairs(lines) do
    if is_completed_heading(line) then
      state.completed_task = true
      table.insert(collected, line)
    elseif state.completed_task then
      if is_blank_line(line) then
        state.completed_task = false
        table.insert(collected, line)
      else
        table.insert(collected, line)
      end
    end
  end

  return collected
end

-- === Header Handling ===
local function find_source_header_index(lines, src_path)
  local header = '# Source: ' .. src_path
  for i, line in ipairs(lines) do
    if line == header then
      return i
    end
  end
  return nil
end

local function ensure_source_header(lines, src_path)
  local idx = find_source_header_index(lines, src_path)
  if not idx then
    table.insert(lines, '# Source: ' .. src_path)
    idx = #lines
  end
  return idx
end

local function find_date_header_index(lines, start_idx, date_header)
  for i = start_idx + 1, #lines do
    if lines[i] == date_header then
      return i
    end
    if lines[i]:match '^# ' then
      break
    end
  end
  return nil
end

local function ensure_date_header(lines, idx, date_header)
  local j = find_date_header_index(lines, idx, date_header)
  if not j then
    table.insert(lines, idx + 1, date_header)
    j = idx + 1
  end
  return j
end

local function insert_tasks(lines, date_idx, tasks)
  for i = #tasks, 1, -1 do
    table.insert(lines, date_idx + 1, tasks[i])
  end
end

-- === Main Handler ===
function M.move_to_completed()
  local buf = 0
  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local completed_tasks = extract_completed_tasks(buf_lines)

  if #completed_tasks == 0 then
    vim.notify('No completed tasks found in buffer', vim.log.levels.INFO)
    return
  end

  -- Get source path and target file
  local src_path = vim.api.nvim_buf_get_name(buf)
  local dst_path = expand_home '~/Documents/personal/planning/completed/completed.md'
  local dst_lines = read_lines(dst_path)

  -- Write to completed.md
  local source_idx = ensure_source_header(dst_lines, src_path)
  local date_header = '## ' .. os.date '%Y-%m-%d'
  local date_idx = ensure_date_header(dst_lines, source_idx, date_header)
  insert_tasks(dst_lines, date_idx, completed_tasks)
  write_lines(dst_path, dst_lines)

  local start_idx, end_idx
  local inside_block = false
  for i, line in ipairs(buf_lines) do
    if is_completed_heading(line) and not inside_block then
      start_idx = i - 1 -- 0-based index
      inside_block = true
    elseif inside_block and is_blank_line(line) then
      end_idx = i -- inclusive
      break
    end
  end

  if inside_block and not end_idx then
    end_idx = #buf_lines -- pretend the "blank" is at EOF
  end

  if start_idx and end_idx then
    -- 🔧 NEW: cap end (Neovim wants end-exclusive, 0-based)
    local end_excl = math.min(end_idx + 1, #buf_lines)
    vim.api.nvim_buf_set_lines(buf, start_idx, end_excl, false, {})
    vim.notify('Completed tasks moved and removed from buffer', vim.log.levels.INFO)
  else
    vim.notify("Could not locate 'Completed' section to remove", vim.log.levels.WARN)
  end
end

return M
