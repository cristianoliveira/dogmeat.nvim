--- Functional programming utilities

local M = {}

--- @param f fun(x: any): boolean
--- @param list any[]
--- @return any[]
function M.filter(f, list)
  local result = {}
  for _, item in ipairs(list) do
    if f(item) then
      table.insert(result, item)
    end
  end
  return result
end

return M
