local M = {}

-- Detect whether a line marks the start of a TODO block
local function is_in_completed(line)
  if line:match '^# Completed' then
    return true
  end
  return false
end
