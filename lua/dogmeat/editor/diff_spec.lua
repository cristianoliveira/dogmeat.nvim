local assert = require("luassert")
local spy = require("luassert.spy")

describe("editor diff", function()
  local diff
  local vim_api_spy
  local vim_cmd_spy
  local vim_fn_spy

  before_each(function()
    -- Mock vim global for testing
    vim_api_spy = {
      nvim_buf_get_name = spy.new(function() return "/current/file.lua" end)
    }

    vim_cmd_spy = spy.new(function() end)

    vim_fn_spy = {
      fnameescape = spy.new(function(path) return path end)
    }

    _G.vim = {
      api = vim_api_spy,
      cmd = vim_cmd_spy,
      fn = vim_fn_spy
    }

    -- Reset module
    package.loaded["dogmeat.editor.diff"] = nil
    diff = require("dogmeat.editor.diff")
  end)

  describe("module structure", function()
    it("export diff_buffer function", function()
      assert.is_function(diff.diff_buffer)
    end)
  end)

  describe("diff_buffer", function()
    it("require file_with_changes option", function()
      diff.diff_buffer({
        file_with_changes = ""
      })

      -- Should not call vim commands if file_with_changes is empty
      assert.spy(vim_cmd_spy).was_not_called()
    end)

    it("use current buffer when current_file not provided", function()
      diff.diff_buffer({
        file_with_changes = "/path/to/changes.lua"
      })

      -- Should call nvim_buf_get_name to get current file
      assert.spy(vim_api_spy.nvim_buf_get_name).was_called_with(0)
    end)

    it("use provided current_file when given", function()
      diff.diff_buffer({
        current_file = "/custom/file.lua",
        file_with_changes = "/path/to/changes.lua"
      })

      -- Should not call nvim_buf_get_name
      assert.spy(vim_api_spy.nvim_buf_get_name).was_not_called()
    end)

    it("open files in vertical split", function()
      diff.diff_buffer({
        current_file = "/current/file.lua",
        file_with_changes = "/changed/file.lua"
      })

      -- Should call vim.cmd twice: edit and vert diffsplit
      assert.spy(vim_cmd_spy).was_called(2)
    end)

    it("escape file paths", function()
      diff.diff_buffer({
        current_file = "/path with spaces/file.lua",
        file_with_changes = "/other path/changes.lua"
      })

      -- Should call fnameescape for both files
      assert.spy(vim_fn_spy.fnameescape).was_called(2)
      assert.spy(vim_fn_spy.fnameescape).was_called_with("/other path/changes.lua")
      assert.spy(vim_fn_spy.fnameescape).was_called_with("/path with spaces/file.lua")
    end)

    it("open in new tab when open_in_tab is true", function()
      diff.diff_buffer({
        file_with_changes = "/changed/file.lua",
        open_in_tab = true
      })

      -- Should call vim.cmd three times: tabnew, edit, and vert diffsplit
      assert.spy(vim_cmd_spy).was_called(3)
    end)

    it("not open new tab when open_in_tab is false", function()
      diff.diff_buffer({
        file_with_changes = "/changed/file.lua",
        open_in_tab = false
      })

      -- Should call vim.cmd twice: edit and vert diffsplit
      assert.spy(vim_cmd_spy).was_called(2)
    end)

    it("not open new tab when open_in_tab is not provided", function()
      diff.diff_buffer({
        file_with_changes = "/changed/file.lua"
      })

      -- Should call vim.cmd twice: edit and vert diffsplit
      assert.spy(vim_cmd_spy).was_called(2)
    end)
  end)

  describe("edge cases", function()
    it("handle nil file_with_changes", function()
      diff.diff_buffer({
        current_file = "/current/file.lua"
      })

      -- Should not call vim.cmd
      assert.spy(vim_cmd_spy).was_not_called()
    end)

    it("handle file paths with special characters", function()
      diff.diff_buffer({
        current_file = "/path/with-special_chars.123.lua",
        file_with_changes = "/other/path-with_chars.456.lua"
      })

      assert.spy(vim_fn_spy.fnameescape).was_called(2)
    end)

    it("handle absolute paths", function()
      diff.diff_buffer({
        current_file = "/absolute/path/to/file.lua",
        file_with_changes = "/absolute/path/to/changes.lua"
      })

      assert.spy(vim_cmd_spy).was_called(2)
    end)

    it("handle relative paths", function()
      diff.diff_buffer({
        current_file = "relative/path/file.lua",
        file_with_changes = "relative/path/changes.lua"
      })

      assert.spy(vim_cmd_spy).was_called(2)
    end)
  end)

  describe("command execution order", function()
    it("edit file_with_changes first, then diffsplit current_file", function()
      local call_order = {}
      vim_cmd_spy = spy.new(function(cmd)
        table.insert(call_order, cmd)
      end)
      _G.vim.cmd = vim_cmd_spy

      package.loaded["dogmeat.editor.diff"] = nil
      diff = require("dogmeat.editor.diff")

      diff.diff_buffer({
        current_file = "/current/file.lua",
        file_with_changes = "/changed/file.lua"
      })

      assert.equals(2, #call_order)
      assert.is_not_nil(call_order[1]:find("edit"))
      assert.is_not_nil(call_order[1]:find("/changed/file.lua"))
      assert.is_not_nil(call_order[2]:find("vert diffsplit"))
      assert.is_not_nil(call_order[2]:find("/current/file.lua"))
    end)

    it("create tab before opening files when open_in_tab is true", function()
      local call_order = {}
      vim_cmd_spy = spy.new(function(cmd)
        table.insert(call_order, cmd)
      end)
      _G.vim.cmd = vim_cmd_spy

      package.loaded["dogmeat.editor.diff"] = nil
      diff = require("dogmeat.editor.diff")

      diff.diff_buffer({
        current_file = "/current/file.lua",
        file_with_changes = "/changed/file.lua",
        open_in_tab = true
      })

      assert.equals(3, #call_order)
      assert.equals("tabnew", call_order[1])
      assert.is_not_nil(call_order[2]:find("edit"))
      assert.is_not_nil(call_order[3]:find("vert diffsplit"))
    end)
  end)
end)
