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

return M
