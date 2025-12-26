--- Configure default Nvim Commands for dogmeat
--- Call setup() to configure
--- @module nvim_commands
local M = {}

local dogmeat = require("dogmeat")
local appender = require("dogmeat.editor.append")

local fetch_with_markdown_cmd = function(opts)
  local macro_name = opts.fargs[1]
  if not macro_name then
    print("No macro name provided")
    return
  end

  dogmeat.go.fetch_with_markdown({
    current_file = vim.fn.expand("%:p"),
    macro = macro_name,

    on_finish = function(resp)
      appender.prepend(0, resp.content)
    end,
  })
end

local fetch_with_instruction = function(opts)
  local macro_name = opts.fargs[1]
  if not macro_name then
    print("No macro name provided")
    return
  end
  local instruction = opts.fargs[2] or ""

  dogmeat.go.fetch_with_instructions(instruction, {
    macro = macro_name,
    current_file = vim.fn.expand("%:p"),

    on_finish = function(resp)
      appender.prepend(0, resp.content)
    end,
  })
end

M.setup = function()
  vim.api.nvim_create_user_command(
    "DmFetchWithMacro",
    fetch_with_markdown_cmd,
    {
      nargs = "*",
      complete = dogmeat.skills.list_macros,
      desc = "Fetch code with macro"
    }
  )

  vim.api.nvim_create_user_command(
    "DMacro", -- Alias to quick use with `DM <macro>`
    fetch_with_instruction,
    {
      nargs = "*",
      complete = dogmeat.skills.list_macros,
      desc = "Fetch code with macro - Alias to DMFetchWithMacro"
    }
  )
end

return M
