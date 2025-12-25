--- Editor/diff related functions

--- @class EditorDiff
--- @field diff_buffer fun(opts: DiffStateOptions) Compare the current buffer with the given file

--- @type EditorDiff
local M = {
  diff_buffer = function() end
}

--- @class DiffStateOptions
--- @field current_file? string The path to the current file. (default: buffer)
--- @field file_with_changes string The path to the file to compare with
--- @field open_in_tab? boolean Whether to open the diff in a new tab

M.diff_buffer = function(opts)
  local file = opts.current_file or vim.api.nvim_buf_get_name(0)
  local file_with_changes = opts.file_with_changes
  if not file_with_changes or file_with_changes == "" then
    print("Cannot diff: buffer has no file_with_changes path")
    return
  end

  -- Create a new tab
  if opts.open_in_tab then
    vim.cmd("tabnew")
  end

  -- Open the buf and file with changes in a vertical split
  vim.cmd("edit " .. vim.fn.fnameescape(file_with_changes))
  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(file))
end

return M
