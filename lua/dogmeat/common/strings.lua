--- Strings helper module
---

local M = {}

--- Split a string into a table of lines
---
---@param str string The string to split
---@param sep? string The separator to use
---@return string[] The lines
M.split = function(str, sep)
  local lines = {}
  for line in str:gmatch(sep or "[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

return M
