--- Vim related functions that invove creating new files, buffers, etc.
--- @module editor
local M = {}

--- @class OnFinishEditingResult
--- @field path string The path to the temporary markdown file
--- @field content string The content of the temporary markdown file

--- Open a temporary markdown file for the user to edit
--- Open in a new tab
--- @param on_finish fun(resp: OnFinishEditingResult) Callback invoked when the user finishes editing the markdown file
--- @return string The path to the temporary markdown file
M.tmp_markdown_file = function(on_finish)
  -- Create a new tab
  vim.cmd("tabnew")

  local temp_file = vim.fn.tempname() .. ".md"
  local temp_buf = vim.fn.bufadd(temp_file)
  vim.fn.bufload(temp_buf)

  -- Set filetype to markdown for better editing
  vim.api.nvim_buf_set_option(temp_buf, 'filetype', 'markdown')

  -- Add some helpful instructions
  local initial_content = {
    "# AIRefactor Instructions",
    ""
  }
  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, initial_content)

  -- Position cursor at the end of the file
  vim.api.nvim_win_set_buf(0, temp_buf)
  vim.api.nvim_win_set_cursor(0, { #initial_content, 0 })

  -- Set up an autocmd to run AIRefactor when the buffer is saved

  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = temp_buf,
    once = true,
    callback = function()
      -- Read the instruction from the temp file
      local lines = vim.api.nvim_buf_get_lines(temp_buf, 0, -1, false)
      local user_instruction = table.concat(lines, "\n")

      -- Extract just the user's instruction (skip the template lines)
      local instruction_start = nil
      for i, line in ipairs(lines) do
        if line == "---" then
          instruction_start = i + 1
          break
        end
      end
      if instruction_start then
        local instruction_lines = {}
        for i = instruction_start, #lines do
          if lines[i] ~= "" or #instruction_lines > 0 then
            table.insert(instruction_lines, lines[i])
          end
        end
        user_instruction = table.concat(instruction_lines, "\n")
      end

      on_finish(user_instruction)

      -- Clean up the temp file
      vim.api.nvim_buf_delete(temp_buf, { force = true })
    end
  })

  -- Return the path to the temp file
  return temp_file
end

return M
