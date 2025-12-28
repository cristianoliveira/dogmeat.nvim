local aichat = require("dogmeat.backends.aichat")
local runner = require("dogmeat.common.runner")
local editor = require("dogmeat.editor")
local strings = require("dogmeat.common.strings")
local aichat_formatter = require("dogmeat.backends.aichat_formatter")

local M = {}

--- Callback invoked when the user finishes fetching code
--- @class OnFinishFetchingCode
--- @field path? string The path to the temporary markdown file
--- @field content? string[] The content of the temporary markdown file
--- @field errors? string[] The errors that occurred during the fetching process

--- @class FetchCodeOptions
--- @field on_finish fun(resp: OnFinishFetchingCode) Callback invoked when the user finishes fetching code
--- @field current_file? string The path to the current file
--- @field macro? string The macro to be used
--- @field model? string The model to be used
--- @field role? string The role to be used
--- @field code? boolean Whether to stream the output code only

--- Go fetch but open a temporary markdown file for instructions
--- @param opts FetchCodeOptions
--- @return string | nil The path to the temporary markdown file
M.fetch_with_markdown = function(opts)
  local formatter = function(res) return res end
  local on_finish_editing = opts.on_finish
  if not on_finish_editing then
    print("No on_finish callback provided")
    return nil
  end


  editor.temp.markdown_file(function(resp)
    local instructions_file = resp.path
    local content = resp.content
    if not instructions_file or not content then
      print("No temp file or content provided")
      return
    end

    if opts.macro then
      formatter = aichat_formatter.format_macro_output
    end

    local cmd = aichat:new()
      :add_file(opts.current_file)
      :add_file(instructions_file)
      :set_macro(opts.macro)
      :set_model(opts.model)
      :set_role(opts.role)
      :set_prompt(
        "Apply the changes in " ..
        opts.current_file ..
        " following the instructions in " ..
        instructions_file
      )
      :code(opts.code)
      :to_command()

    runner.async(cmd, {
      on_success = function(code, res)
        if code ~= 0 then
          print("[ERROR] job failed with code", code)
          on_finish_editing({ errors = { res.stdout, res.stderr } })
          return
        end

        on_finish_editing({
          path = resp.path,
          content = formatter(strings.split(res.stdout)),
        })
      end,

      on_error = function(stderr, _)
        print("[ERROR] job failed with stderr", stderr)
        on_finish_editing({ errors = { stderr } })
      end,
    })
  end)
end


--- Go fetch code from aichat with instruction (no mardown file)
--- @param instructions string The instructions to be used
--- @param opts FetchCodeOptions
M.fetch_with_instructions = function(instructions, opts)
  local formatter = function(res) return res end
  local on_finish = opts.on_finish
  if not on_finish then
    print("No on_finish callback provided")
    return nil
  end

  if opts.macro then
    formatter = aichat_formatter.format_macro_output
  end

  local cmd = aichat:new()
    :add_file(opts.current_file)
    :set_macro(opts.macro)
    :set_model(opts.model)
    :set_role(opts.role)
    :set_prompt(
      "Apply the changes in " ..
      opts.current_file ..
      " following the instructions in " ..
      instructions
    )
    :code(opts.code)
    :to_command()

  return runner.async(cmd, {
    on_success = function(code, res)
      if code ~= 0 then
        print("[ERROR] job failed with code", code)
        on_finish({ errors = { res.stdout, res.stderr } })
        return
      end

      on_finish({ content = formatter(strings.split(res.stdout)) })
    end,

    on_error = function(stderr, _)
      print("[ERROR] job failed with stderr", stderr)
      on_finish({ errors = { stderr } })
    end,
  })
end

--- @class GoFetchTextOptions
--- @field on_finish fun(resp: OnFinishFetchingCode) Callback invoked when the user finishes fetching code
--- @field current_file? string The path to the current file

--- Go fetch code from aichat
--- @param opts GoFetchTextOptions
--- @return string | nil The path to the temporary markdown file
M.go_fetch_text = function(opts)
  local on_finish_editing = opts.on_finish
  if not on_finish_editing then
    print("No on_finish callback provided")
    return nil
  end
end

return M
