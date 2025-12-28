local cfgs = require("dogmeat.configs")

local M = {}

M.configs = cfgs.default

M.setup = function(opts)
  M.configs = cfgs.setup(opts)
end

M.go = require("dogmeat.abilities")
M.skills = require("dogmeat.skills")
M.agents = require("dogmeat.agents")

return M
