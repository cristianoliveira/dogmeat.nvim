local aichat = require("dogmeat.backends.aichat")
local runner = require("dogmeat.common.runner")
local editor = require("dogmeat.common.editor")

local M = {}

--- Callback invoked when the user finishes fetching code
--- @class OnFinishFetchingCode
--- @field path string The path to the temporary markdown file
--- @field content string The content of the temporary markdown file

--- @class FetchCodeOptions
--- @field on_finish fun(resp: OnFinishFetchingCode) Callback invoked when the user finishes fetching code
--- @field current_file? string The path to the current file
--- @field prompt? string The prompt to be used, other than the default

--- Go fetch code from aichat
--- @param opts FetchCodeOptions
--- @return string | nil The path to the temporary markdown file
M.fetch_code = function(opts)
  local on_finish_editing = opts.on_finish
  if not on_finish_editing then
    print("No on_finish callback provided")
    return nil
  end

  editor.tmp_markdown_file(function(resp)
    local instructions_file = resp.path
    local content = resp.content
    if not instructions_file or not content then
      print("No temp file or content provided")
      return
    end

    local cmd = aichat:new()
      :add_file(opts.current_file)
      :add_file(instructions_file)
      :prompt(
        "Apply the changes in " ..
        opts.current_file ..
        " following the instructions in " ..
        instructions_file
      )
      :code(true)
      :to_command()

    print(vim.inspect(cmd))
    runner.async(cmd, {
      on_success = function(code, res)
        if code ~= 0 then
          print("[ERROR] job failed with code", code)
          print(vim.inspect(res))
          return
        end

        print(vim.inspect(res))

        on_finish_editing({
          path = instructions_file,
          content = res.stdout,
        })
      end,

      on_error = function(stderr, res)
        print("[ERROR] job failed with stderr", stderr)
        print(vim.inspect(res))
      end,
    })
  end)
end

return M
