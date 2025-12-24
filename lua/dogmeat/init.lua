local M = {}

M.config = {
  -- Default configuration
  aichat_cmd = "aichat",
  roles = {},
  macros = {},
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
