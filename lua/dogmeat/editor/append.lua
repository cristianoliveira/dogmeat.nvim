--- Append text to the end of the current buffer

local M = {}

--- Append text to the end of the current buffer
--- @param buffer? integer The buffer to be appended to (default: current buffer)
--- @param content string[] The text to be appended
M.append = function(buffer, content)
  if not content then
    print("No content provided")
    return
  end
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end

  vim.api.nvim_buf_set_lines(buffer, -1, -1, false, content)
end

--- Prepend text to the beginning of the current buffer
--- @param buffer? integer The buffer to be prepended to (default: current buffer)
--- @param content string[] The text to be prepended
M.prepend = function(buffer, content)
  if not content then
    print("No content provided")
    return
  end
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end

  vim.api.nvim_buf_set_lines(buffer, 0, 0, false, content)
end

--- Append text after a given line
--- @param buffer? integer The buffer to be appended to (default: current buffer)
--- @param line integer The line to append after
--- @param content string[] The text to be appended
M.append_after = function(buffer, line, content)
  if not content then
    print("No content provided")
    return
  end
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  if not line then
    line = vim.api.nvim_buf_line_count(buffer)
  end

  vim.api.nvim_buf_set_lines(buffer, line, -1, false, content)
end

--- Prepend text before a given line
--- @param buffer? integer The buffer to be prepended to (default: current buffer)
--- @param line integer The line to prepend before
--- @param content string[] The text to be prepended
M.prepend_before = function(buffer, line, content)
  if not content then
    print("No content provided")
    return
  end
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  if not line then
    line = 0
  end

  vim.api.nvim_buf_set_lines(buffer, line, 0, false, content)
end

return M
