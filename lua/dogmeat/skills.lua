local aichat = require("dogmeat.backends.aichat")
local runner = require("dogmeat.common.runner")
local fn = require("dogmeat.common.fn")

local M = {}

local exectute_and_filter = function(cmd, partial)
  local result = runner.execute(cmd)

  table.sort(result)
  if not partial then
    return result
  end

  local res =fn.filter(function(item)
    local r = string.find(item, partial)
    return r ~= nil
  end, result)
  -- sort alphabetically
  return res
end
-- Macros are found by:
-- aichat --list-macros
--
-- @param partial? string The partial to filter the macros
-- @return string[] The macros
M.list_macros = function(partial)
  return exectute_and_filter(aichat.list_macros(), partial)
end

-- List Roles are found by:
-- aichat --list-roles
--
-- @param partial? string The partial to filter the roles
-- @return string[] The roles
M.list_roles = function(partial)
  local cmd = aichat.list_roles()
  return exectute_and_filter(cmd, partial)
end

-- List Models are found by:
-- aichat --list-models
--
-- @param partial? string The partial to filter the models
-- @return string[] The models
M.list_models = function(partial)
  local cmd = aichat.list_models()
  return exectute_and_filter(cmd, partial)
end

return M
