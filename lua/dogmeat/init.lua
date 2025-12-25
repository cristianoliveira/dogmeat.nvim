local cfgs = require("dogmeat.configs")
local aichat = require("dogmeat.backends.aichat")
local runner = require("dogmeat.common.runner")
local editor = require("dogmeat.common.editor")

local M = {}

M.configs = cfgs.default

M.setup = function(opts)
  M.configs = cfgs.setup(opts)
end

--- Callback invoked when the user finishes fetching code
--- @class OnFinishFetchingCode
--- @field path string The path to the temporary markdown file
--- @field content string The content of the temporary markdown file

--- @class GoFetchCodeOptions
--- @field on_finish fun(resp: OnFinishFetchingCode) Callback invoked when the user finishes fetching code
--- @field current_file? string The path to the current file
--- @field prompt? string The prompt to be used, other than the default

--- Go fetch code from aichat
--- @param opts GoFetchCodeOptions
--- @return string | nil The path to the temporary markdown file
M.go_fetch_code = function(opts)
  if not opts.on_finish then
    print("No on_finish callback provided")
    return nil
  end

  local on_finish_editing = function(resp)
    local temp_file = resp.path
    local content = resp.content
    if not temp_file or not content then
      print("No temp file or content provided")
      return
    end
    local cmd = aichat:new()
                      :add_file(opts.current_file)
                      :add_file(temp_file)
                      :prompt("Instructions for " .. temp_file)
                      :code(true)
                      :to_command()
    print(vim.inspect(cmd))
    runner.async(cmd, {
      on_success = function(code, res)
        print("job finished with code", code)
        print(vim.inspect(res))
      end,
      on_error = function(stderr, res)
        print("job failed with stderr", stderr)
        print(vim.inspect(res))
      end,
    })
  end
  local temp_file = editor.tmp_markdown_file(on_finish_editing)
end


return M
