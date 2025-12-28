--- Functional programming utilities

local M = {}

--- Filter a list using a predicate function
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

--- Map a list using a function
--- @param f fun(x: any): any
--- @param list any[]
--- @return any[]
function M.map(f, list)
  local result = {}
  for _, item in ipairs(list) do
    table.insert(result, f(item))
  end
  return result
end

return M
