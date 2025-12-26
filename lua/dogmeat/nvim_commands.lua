--- Configure default Nvim Commands for dogmeat
--- Call setup() to configure
--- @module nvim_commands
local M = {}

local dogmeat = require("dogmeat")
local editor = require("dogmeat.editor.diff")
local temp = require("dogmeat.editor.temp")

local fetch_with_markdown_cmd = function(opts)
  local macro_name = opts.fargs[1]
  if not macro_name then
    print("No macro name provided")
    return
  end

  local current_file = vim.fn.expand("%:p")
  local current_ext = vim.fn.expand("%:e")

  dogmeat.go.fetch_with_markdown({
    current_file = current_file,
    macro = macro_name,

    on_finish = function(resp)
      local content_as_table = vim.split(resp.content, "\n")
      local temp_file = temp.create_temp_file({
        ext = current_ext,
        content = content_as_table,
      })

      editor.diff_buffer({
        current_file = current_file,
        file_with_changes = temp_file,
        open_in_tab = true,
      })
    end,

  })
end

M.setup = function()
  vim.api.nvim_create_user_command(
    "DmFetchWithMacro",
    fetch_with_markdown_cmd,
    {
      nargs = 1,
      complete = function()
        return dogmeat.skills.list_macros()
      end,
      desc = "Fetch code with macro"
    }
  )

  vim.api.nvim_create_user_command(
    "DMacro", -- Alias to quick use with `DM <macro>`
    fetch_with_markdown_cmd,
    {
      nargs = 1,
      complete = function()
        return dogmeat.skills.list_macros()
      end,
      desc = "Fetch code with macro - Alias to DMFetchWithMacro"
    }
  )
end

return M
