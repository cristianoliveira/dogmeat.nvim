--- Configure default Nvim Commands for dogmeat
--- Call setup() to configure
--- @module nvim_commands
local selection = require("dogmeat.editor.selection")

local M = {}

local dogmeat = require("dogmeat")
local appender = require("dogmeat.editor.append")
local editor = require("dogmeat.editor")

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

local fetch_code_with_markdown = function()
  local current_file = vim.fn.expand("%:p")
  dogmeat.go.fetch_with_markdown({
    current_file = current_file,
    role = "code-patch",
    code = true,

    on_finish = function(resp)
      editor.diff.diff_buffer({
        current_file = current_file,
        file_with_changes = resp.path,
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

  vim.api.nvim_create_user_command(
    "DogmeatFetchCode",
    fetch_code_with_markdown,
    {
      nargs = 0,
      desc = "Fetch code with markdown",
    }
  )

  vim.api.nvim_create_user_command(
    "DFCode",
    fetch_code_with_markdown,
    {
      nargs = 0,
      desc = "Fetch code with markdown - Alias to DogmeatFetchCode",
    }
  )

  vim.api.nvim_create_user_command(
    "DAgent",
    function(args)
      local agent = args.fargs[1]

      local initial_content = { }
      local selected_code = selection.get_selection()
      if selected_code ~= "" then
        table.insert(
          initial_content,
          "lines: " .. selected_code.start_line .. "-" .. selected_code.end_line
        )
        table.insert(initial_content, "```code")
        local content = string.gsub(selected_code.text, "\n", "\\n")
        table.insert(initial_content, content)
        table.insert(initial_content, "```")
      end


      editor.temp.markdown_file(function(resp)
        local content = string.gsub(resp.content, "\n", "\\n")
        local cmd = vim.fn.shellescape(agent) .. " " .. vim.fn.shellescape(content)
        vim.cmd("tabnew")
        vim.cmd("term " .. cmd)
      end, { initial_content = initial_content })
    end,
    {
      nargs = "*",
      range ="%",
      complete = dogmeat.agents.list_agents,
      desc = "Fetch code with agent"
    }
  )
end

return M
