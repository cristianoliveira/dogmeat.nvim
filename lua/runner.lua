-- runner.lua
-- Just a helper to run the plugin for development, to use it:
-- :source %
local dogmeat = require("dogmeat")
local editor = require("dogmeat.editor.diff")
local temp = require("dogmeat.editor.temp")
local nvim_commands = require("dogmeat.nvim_commands")

nvim_commands.setup()

-- local current_file = vim.fn.expand("%:p")
-- local current_ext = vim.fn.expand("%:e")

-- dogmeat.go.fetch_with_markdown({
--   current_file = current_file,
--   code = true,
--   on_finish = function(resp)
--     local content_as_table = vim.split(resp.content, "\n")
--     local temp_file = temp.create_temp_file({
--       ext = current_ext,
--       content = content_as_table,
--     })
--
--     editor.diff_buffer({
--       current_file = current_file,
--       file_with_changes = temp_file,
--       open_in_tab = true,
--     })
--   end,
-- })

-- Using macro
-- dogmeat.go.fetch_with_markdown({
--   current_file = current_file,
--   code = true,
--   macro = "git-commit",
--   on_finish = function(resp)
--     local content_as_table = vim.split(resp.content, "\n")
--     local temp_file = temp.create_temp_file({
--       ext = current_ext,
--       content = content_as_table,
--     })
--
--     editor.diff_buffer({
--       current_file = current_file,
--       file_with_changes = temp_file,
--       open_in_tab = true,
--     })
--   end,
-- })

-- dogmeat.go.fetch_code_with_instruction(
--   'comment this code out',
--   {
--     current_file = current_file,
--
--     on_finish = function(resp)
--       local content_as_table = vim.split(resp.content, "\n")
--       local temp_file = temp.create_temp_file({
--         ext = current_ext,
--         content = content_as_table,
--       })
--
--       editor.diff_buffer({
--         current_file = current_file,
--         file_with_changes = temp_file,
--         open_in_tab = true,
--       })
--     end,
--   }
-- )

-- local macros = dogmeat.skills.list_macros()
-- print(vim.inspect(macros))
--
-- local roles = dogmeat.skills.list_roles()
-- print(vim.inspect(roles))
--
-- local models = dogmeat.skills.list_models()
-- print(vim.inspect(models))
