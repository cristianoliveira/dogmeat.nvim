local cfgs = require("dogmeat.configs")
local runner = require("dogmeat.common.runner")
local editor = require("dogmeat.common.editor")

local M = {}

M.configs = cfgs.default

M.setup = function(opts)
  M.configs = cfgs.setup(opts)
end

--- Macro Options
--- @class MacroOptions
--- @field macro_name string The name of the macro to be executed
--- @field prompt string The prompt to be used for the macro
--- @field on_success fun(code: integer, res: vim.SystemCompleted)|nil
---   Callback invoked when the command completes successfully
--- @field on_error fun(stderr: string, res: vim.SystemCompleted)|nil
---   Callback invoked when the command fails

--- Macro function
--- @param opts MacroOptions
M.macro = function(opts)
  local command = {
    M.configs.aichat_bin,
    opts.macro_name,
  }

  -- If prompt isn't provided, open a temporary markdown file for the user to edit
  -- and pipe it to the macro
  if not opts.prompt then
    editor.tmp_markdown_file(function(resp)
      table.insert(command, "-f")
      table.insert(command, resp.path)
      print('@@@@@@@@@ command', vim.inspect(command))
      local result = runner.execute(command)
      print('@@@@@@@@@ result', vim.inspect(result))
    end)
  else
    table.insert(command, "-p")
    table.insert(command, opts.prompt)
    print('@@@@@@@@@ command', vim.inspect(command))
  end
end

return M
