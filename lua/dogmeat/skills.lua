local aichat = require("dogmeat.backends.aichat")
local runner = require("dogmeat.common.runner")

local M = {}

-- Macros are found by:
-- aichat --list-macros
--
-- @return string[] The macros
M.list_macros = function()
  local cmd = aichat.list_macros()
  return runner.execute(cmd)
end

-- List Roles are found by:
-- aichat --list-roles
--
-- @return string[] The roles
M.list_roles = function()
  local cmd = aichat.list_roles()
  return runner.execute(cmd)
end

-- List Models are found by:
-- aichat --list-models
--
-- @return string[] The models
M.list_models = function()
  local cmd = aichat.list_models()
  return runner.execute(cmd)
end

return M
