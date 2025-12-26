local cfgs = require("dogmeat.configs")
local abilities = require("dogmeat.abilities")

local M = {}

M.configs = cfgs.default

M.setup = function(opts)
  M.configs = cfgs.setup(opts)
end

M.go = abilities
M.skills = require("dogmeat.skills")

return M
