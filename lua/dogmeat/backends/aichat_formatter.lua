--- Aichat from https://github.com/sigoden/aichat
--- Output formatter and parser

local M = {}

--- Macro output format
--- @param output string[] The output to be cleaned (the '>> <command>')
--- @return string[] The cleaned output
M.format_macro_output = function(output)
  local cleaned_output = {}
  for _, line in ipairs(output) do
    if not string.find(line, "^>>") then
      table.insert(cleaned_output, line)
    end
  end
  return cleaned_output
end

return M
