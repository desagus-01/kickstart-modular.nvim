-- ~/.config/nvim/lua/planning_index.lua
--
-- Auto-generates ~/Documents/personal/planning/index.md whenever anything
-- inside that tree changes (create/delete/rename/write).
--
-- Heading levels:
--   #  top-level directory
--   ## sub-directory
--   ### sub-sub-directory …
-- Files become Markdown links underneath the directory that owns them.
--
-- Only runs when the *current* working directory **is exactly**
-- ~/Documents/personal/planning (so it won’t fire when you’re elsewhere).

-- Files to ignore
local ignore_dirs = { '.git' }
local ignore_files = { 'index.md' }

local M = {}

-- ╭──────────────────────── configuration ────────────────────────╮
local root = vim.fn.expand '~/Documents/personal/planning' -- canonical path
local index_file = root .. '/index.md'
local excluded = { index_file } -- don’t index us!
-- ╰──────────────────────────────────────────────────────────────╯

-- tiny helpers ---------------------------------------------------
local uv = vim.loop

local function should_ignore(name, list)
  for _, pat in ipairs(list) do
    if name == pat then
      return true
    end
  end
  return false
end

local function is_dir(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == 'directory'
end

local function is_markdown(path)
  return path:sub(-3) == '.md'
end

-- Best-effort “pretty name” for headings & links
local function prettify(filename)
  local name = filename:gsub('%.md$', '') -- strip extension
  name = name:gsub('[_%-%s]+', ' ') -- _ or - → space
  return (name:sub(1, 1):upper() .. name:sub(2)) -- capitalise 1st letter
end

-- Grab first Markdown H1/H2/H3 line in a file; fallback to filename
local function first_heading(path, fallback)
  local fd = io.open(path, 'r')
  if not fd then
    return fallback
  end
  for line in fd:lines() do
    local title = line:match '^#+%s+(.+)'
    if title then
      fd:close()
      return title
    end
  end
  fd:close()
  return fallback
end

-------------------------------------------------------------------
-- Recursively walk the directory, building markdown lines.
-------------------------------------------------------------------
---@param dir  string  -- absolute path we’re scanning
---@param depth integer  -- how deep are we (root=1)?
---@param lines table   -- accumulator
local function scan(dir, depth, lines)
  local handle = uv.fs_scandir(dir)
  if not handle then
    return
  end

  local folders, files = {}, {}
  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    -- 1️⃣ skip dot-files / dot-dirs outright
    if name:sub(1, 1) == '.' then
      goto continue
    end

    -- 2️⃣ custom ignore tables
    if typ == 'directory' and should_ignore(name, ignore_dirs) then
      goto continue
    end
    if typ == 'file' and should_ignore(name, ignore_files) then
      goto continue
    end

    local path = dir .. '/' .. name
    if vim.tbl_contains(excluded, path) then
      goto continue
    end
    if typ == 'directory' then
      table.insert(folders, name)
    elseif typ == 'file' and is_markdown(name) then
      table.insert(files, name)
    end
    ::continue::
  end
  table.sort(folders)
  table.sort(files)

  -- print directory heading
  local heading = string.rep('#', depth) .. ' ' .. prettify(vim.fn.fnamemodify(dir, ':t'))
  table.insert(lines, '')
  table.insert(lines, heading)

  -- files first (makes small leaves look nicer)
  for _, file in ipairs(files) do
    local rel = dir:gsub('^' .. root .. '/', '') .. '/' .. file
    local link = ('[%s](%s)'):format(first_heading(dir .. '/' .. file, prettify(file)), rel)
    table.insert(lines, ('- %s'):format(link))
  end

  -- recurse into sub-dirs
  for _, folder in ipairs(folders) do
    scan(dir .. '/' .. folder, depth + 1, lines)
  end
end

-------------------------------------------------------------------
-- Public: generate the index & write it atomically
-------------------------------------------------------------------
function M.generate_index()
  if uv.cwd() ~= root then
    -- We are not *inside* the planning root; bail out early.
    return
  end
  local lines = {
    '<!-- autogenerated by planning_index.nvim; DO NOT EDIT BY HAND -->',
  }
  scan(root, 1, lines)

  -- Write only when content actually changed (saves redraws)
  local new = table.concat(lines, '\n') .. '\n'
  local fd_old = io.open(index_file, 'r')
  local old = fd_old and fd_old:read '*a' or ''
  if fd_old then
    fd_old:close()
  end
  if old ~= new then
    local fd = assert(io.open(index_file, 'w'))
    fd:write(new)
    fd:close()
    vim.notify('planning_index: index.md regenerated', vim.log.levels.INFO, { title = 'Planning Index' })
  end
end

-------------------------------------------------------------------
-- Autocmds – fire on relevant events *inside* the root directory
-------------------------------------------------------------------
local group = vim.api.nvim_create_augroup('PlanningIndex', { clear = true })

-- These catch creation, write, delete, rename
local events = { 'BufWritePost', 'BufFilePost', 'BufDelete', 'BufNewFile' }

vim.api.nvim_create_autocmd(events, {
  group = group,
  pattern = root .. '/**',
  callback = M.generate_index,
})

-- Regenerate index the moment you enter the directory in an nvim session
vim.api.nvim_create_autocmd('DirChanged', {
  group = group,
  callback = function(ev)
    if ev.cwd == root then
      M.generate_index()
    end
  end,
})

return M
