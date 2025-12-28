local M = {}

--- Create temporary file options
--- @class CreateTempFileOptions
--- @field ext? string The file extension, defaults to "txt"
--- @field content? string[] The content of the file, defaults to an empty array

--- Create a temporary file
--- @param opts CreateTempFileOptions
--- @return string The path to the temporary file
M.create_temp_file = function(opts)
  local ext = opts.ext or "txt" -- FIXME: not sure about this
  local content = opts.content or {}

  local temp_file = vim.fn.tempname() .. "." .. ext
  local temp_buf = vim.fn.bufadd(temp_file)

  vim.fn.bufload(temp_buf)
  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(temp_buf, 'filetype', ext)
  vim.api.nvim_win_set_buf(0, temp_buf)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  return temp_file
end

--- @class OnFinishEditingResult
--- @field path string The path to the temporary markdown file
--- @field content string The content of the temporary markdown file

--- @class CreateTempFileOptions
--- @field initial_content? string[] The content of the file, defaults to an empty array

--- Open a temporary markdown file for the user to edit
--- Open in a new tab
--- @param on_finish fun(resp: OnFinishEditingResult) Callback invoked when the user finishes editing the markdown file
--- @param opts? CreateTempFileOptions
--- @return string The path to the temporary markdown file
M.markdown_file = function(on_finish, opts)
  -- Create a new tab
  vim.cmd("tabnew")

  local temp_file = vim.fn.tempname() .. ".md"
  local temp_buf = vim.fn.bufadd(temp_file)
  vim.fn.bufload(temp_buf)

  -- Set filetype to markdown for better editing
  vim.api.nvim_buf_set_option(temp_buf, 'filetype', 'markdown')

  local all_buffers = vim.api.nvim_list_bufs()
  local all_buffers_names = vim.tbl_map(function(buf) return vim.api.nvim_buf_get_name(buf) end, all_buffers)

  -- Add some helpful instructions
  local initial_content = {
    "# AIRefactor Instructions",
    "<!-- current opened files and buffers -->",
  }

  for _, buf_name in ipairs(all_buffers_names) do
    if buf_name ~= temp_file then
      table.insert(initial_content, "<!-- " .. vim.fn.fnameescape(buf_name) .. " -->")
    end
  end

  if opts and opts.initial_content then
    initial_content = vim.list_extend(initial_content, opts.initial_content)
  end

  initial_content = vim.list_extend(initial_content, {
    "<!-- user's instruction -->",
    "",
  })

  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, initial_content)

  -- Position cursor at the end of the file
  vim.api.nvim_win_set_buf(0, temp_buf)
  vim.api.nvim_win_set_cursor(0, { #initial_content, 0 })

  -- Call callback on closing the buffer
  local group = vim.api.nvim_create_augroup("DogmeatAutocmds", { clear = true })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    buffer = temp_buf,
    callback = function()
      -- Read the instruction from the temp file
      local lines = vim.api.nvim_buf_get_lines(temp_buf, 0, -1, false)
      local content = table.concat(lines, "\n")

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
        content = table.concat(instruction_lines, "\n")
      end

      on_finish({ path = temp_file, content = content })
    end
  })

  -- Return the path to the temp file
  return temp_file
end

return M
