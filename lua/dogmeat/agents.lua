local fn = require("dogmeat.common.fn")

local agents = {
  {
    name = "codex",
    bin = "codex",
  },
}

local M = {}

--- Return a list of all agents
--- @return table<string,any> # List of agents
M.list_agents = function()
  return fn.map(function(agent)
    return agent.name
  end, agents)
end

return M
