--- Aichat from https://github.com/sigoden/aichat
--- Module for building aichat commands
-- @module aichat AichatBuilder

--- @class AichatConfigs
--- @field aichat_bin string The path to the aichat binary

--- @class AichatBuilder
--- @field new fun(self: AichatBuilder, opts?: AichatConfigs): AichatBuilder
--- @field macro fun(self: AichatBuilder, macro_name: string): AichatBuilder
--- @field model fun(self: AichatBuilder, model: string): AichatBuilder
--- @field role fun(self: AichatBuilder, role: string): AichatBuilder
--- @field file fun(self: AichatBuilder, file: string): AichatBuilder
--- @field prompt fun(self: AichatBuilder, prompt: string): AichatBuilder
--- @field code fun(self: AichatBuilder, code: boolean): AichatBuilder
--- @field to_command fun(): string[]
local M = {
  --- @type AichatConfigs The default configurations
  configs = {
    aichat_bin = "aichat",
  }
}

---@class AichatArgs
---@field macro_name? string The name of the macro to be executed
---@field model? string The model to be used in the macro
---@field role? string The role to be used
---@field files? table<string> The files to be used
---@field code? boolean Whether to stream the output code only
local args = {
  macro_name = nil,
  model = nil,
  role = nil,
  files = nil,
  prompt = nil,
  code = false,
}

--- Command builder
--- @return AichatConfigs The updated configurations
M.new = function(self, opts)
  args = {}
  self.configs = vim.tbl_deep_extend("force", M.configs, opts or {})
  return self or M
end

--- Adds a file to the command
---@param file string The file to be added
M.add_file = function(self, file)
  if not args.files then
    args.files = {}
  end
  table.insert(args.files, file)
  return self
end

--- Add a role to the command
M.add_role = function(self, role)
  args.role = role
  return self
end

--- Add a model to the command
---@param model string The model to be added
M.add_model = function(self, model)
  args.model = model
  return self
end

--- Set the macro name
--- @param macro_name string The name of the macro to be executed
M.macro = function(self, macro_name)
  args.macro_name = macro_name
  return self
end

--- Set the prompt
--- @param prompt string The prompt to be used
M.prompt = function(self, prompt)
  args.prompt = prompt
  return self or M
end

--- Set the code flag
--- @param code boolean Whether to stream the output code only
M.code = function(self, code)
  args.code = code
  return self
end

-- Build the command
-- @return table<string> The command to be executed
function M.to_command()
  local command = {
    M.configs.aichat_bin,
  }

  if args.code then
    table.insert(command, "--code")
  end

  if args.macro_name then
    table.insert(command, "--macro")
    table.insert(command, args.macro_name)
  end

  if args.model then
    table.insert(command, "--model")
    table.insert(command, args.model)
  end

  if args.role then
    table.insert(command, "--role")
    table.insert(command, args.role)
  end

  if args.files then
    for _, file in ipairs(args.files) do
      table.insert(command, "--file")
      table.insert(command, file)
    end
  end

  if args.prompt then
    table.insert(command, " ")
    table.insert(command, vim.fn.shellescape(args.prompt))
  end

  if args.macro_name then
    -- Ignore the '>> <command>' outputs from aichat
    table.insert(command, "|")
    table.insert(command, "sed -e 's/^>>.*$//g'")
  end

  return command
end

--- List macros command
--- @return string[] The command to be executed
M.list_macros = function()
  return { M.configs.aichat_bin, "--list-macros" }
end

--- List roles command
--- @return string[] The command to be executed
M.list_roles = function()
  return { M.configs.aichat_bin, "--list-roles" }
end

--- List models command
--- @return string[] The command to be executed
M.list_models = function()
  return { M.configs.aichat_bin, "--list-models" }
end

return M
