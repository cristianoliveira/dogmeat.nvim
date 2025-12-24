--- @class DogmeatConfigs
--- @field aichat_bin string The path to the aichat binary
--- @field roles table<string, string> The roles to be used in the macros
--- @field macros table<string, string> The macros to be used in the macros

--- Module for managing configurations
-- @module dogmeat
-- @alias M
local M = {
  --- @type DogmeatConfigs The default configurations
  default = {
    aichat_bin = "aichat",
    roles = {},
    macros = {},
  }
}

--- Setup function
--- @param opts DogmeatConfigs The configurations to be used
--- @return DogmeatConfigs The updated configurations
M.setup = function(opts)
  return vim.tbl_deep_extend("force", M.default, opts or {})
end

return M
