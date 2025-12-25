local assert = require("luassert")
local spy = require("luassert.spy")

describe("editor temp", function()
  local temp
  local vim_fn_spy
  local vim_api_spy

  before_each(function()
    -- Mock vim.fn functions
    vim_fn_spy = {
      tempname = spy.new(function() return "/tmp/nvim_temp_12345" end),
      bufadd = spy.new(function() return 42 end),
      bufload = spy.new(function() end)
    }

    -- Mock vim.api functions
    vim_api_spy = {
      nvim_buf_set_lines = spy.new(function() end),
      nvim_buf_set_option = spy.new(function() end),
      nvim_win_set_buf = spy.new(function() end),
      nvim_win_set_cursor = spy.new(function() end)
    }

    _G.vim = {
      fn = vim_fn_spy,
      api = vim_api_spy
    }

    -- Reset module
    package.loaded["dogmeat.editor.temp"] = nil
    temp = require("dogmeat.editor.temp")
  end)

  describe("module structure", function()
    it("export create_temp_file function", function()
      assert.is_function(temp.create_temp_file)
    end)
  end)

  describe("create_temp_file", function()
    it("return a temp file path", function()
      local path = temp.create_temp_file({})

      assert.is_string(path)
      assert.is_not_nil(path:find("/tmp/nvim_temp"))
    end)

    it("use default txt extension when not provided", function()
      local path = temp.create_temp_file({})

      assert.is_not_nil(path:find("%.txt$"))
    end)

    it("use provided extension", function()
      local path = temp.create_temp_file({ ext = "lua" })

      assert.is_not_nil(path:find("%.lua$"))
    end)

    it("support various file extensions", function()
      local extensions = { "md", "py", "js", "json", "yaml" }

      for _, ext in ipairs(extensions) do
        local path = temp.create_temp_file({ ext = ext })
        assert.is_not_nil(path:find("%." .. ext .. "$"), "Expected ." .. ext .. " extension")
      end
    end)

    it("call tempname to generate temp path", function()
      temp.create_temp_file({})

      assert.spy(vim_fn_spy.tempname).was_called(1)
    end)

    it("create a buffer for the temp file", function()
      temp.create_temp_file({})

      assert.spy(vim_fn_spy.bufadd).was_called(1)
    end)

    it("load the buffer", function()
      temp.create_temp_file({})

      assert.spy(vim_fn_spy.bufload).was_called_with(42) -- buffer number from bufadd mock
    end)

    it("set buffer lines with empty content by default", function()
      temp.create_temp_file({})

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, {})
    end)

    it("set buffer lines with provided content", function()
      local content = { "line 1", "line 2", "line 3" }
      temp.create_temp_file({ content = content })

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)

    it("set filetype to extension", function()
      temp.create_temp_file({ ext = "lua" })

      assert.spy(vim_api_spy.nvim_buf_set_option).was_called_with(42, 'filetype', 'lua')
    end)

    it("set the buffer in the current window", function()
      temp.create_temp_file({})

      assert.spy(vim_api_spy.nvim_win_set_buf).was_called_with(0, 42)
    end)

    it("set cursor to beginning of file", function()
      temp.create_temp_file({})

      assert.spy(vim_api_spy.nvim_win_set_cursor).was_called_with(0, { 1, 0 })
    end)
  end)

  describe("content handling", function()
    it("handle single line content", function()
      local content = { "single line" }
      temp.create_temp_file({ content = content })

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)

    it("handle multi-line content", function()
      local content = { "line 1", "line 2", "line 3", "line 4" }
      temp.create_temp_file({ content = content })

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)

    it("handle empty lines in content", function()
      local content = { "line 1", "", "line 3" }
      temp.create_temp_file({ content = content })

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)

    it("handle content with special characters", function()
      local content = { "line with 'quotes'", "line with \"double quotes\"", "line with \\backslash" }
      temp.create_temp_file({ content = content })

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)
  end)

  describe("extension handling", function()
    it("handle markdown extension", function()
      local path = temp.create_temp_file({ ext = "md" })

      assert.is_not_nil(path:find("%.md$"))
      assert.spy(vim_api_spy.nvim_buf_set_option).was_called_with(42, 'filetype', 'md')
    end)

    it("handle python extension", function()
      local path = temp.create_temp_file({ ext = "py" })

      assert.is_not_nil(path:find("%.py$"))
      assert.spy(vim_api_spy.nvim_buf_set_option).was_called_with(42, 'filetype', 'py')
    end)

    it("handle lua extension", function()
      local path = temp.create_temp_file({ ext = "lua" })

      assert.is_not_nil(path:find("%.lua$"))
      assert.spy(vim_api_spy.nvim_buf_set_option).was_called_with(42, 'filetype', 'lua')
    end)
  end)

  describe("complete flow", function()
    it("execute all steps in correct order", function()
      local call_order = {}

      vim_fn_spy.tempname = spy.new(function()
        table.insert(call_order, "tempname")
        return "/tmp/nvim_temp_12345"
      end)

      vim_fn_spy.bufadd = spy.new(function()
        table.insert(call_order, "bufadd")
        return 42
      end)

      vim_fn_spy.bufload = spy.new(function()
        table.insert(call_order, "bufload")
      end)

      vim_api_spy.nvim_buf_set_lines = spy.new(function()
        table.insert(call_order, "set_lines")
      end)

      vim_api_spy.nvim_buf_set_option = spy.new(function()
        table.insert(call_order, "set_option")
      end)

      vim_api_spy.nvim_win_set_buf = spy.new(function()
        table.insert(call_order, "set_buf")
      end)

      vim_api_spy.nvim_win_set_cursor = spy.new(function()
        table.insert(call_order, "set_cursor")
      end)

      _G.vim.fn = vim_fn_spy
      _G.vim.api = vim_api_spy

      package.loaded["dogmeat.editor.temp"] = nil
      temp = require("dogmeat.editor.temp")

      temp.create_temp_file({ ext = "lua", content = { "test" } })

      assert.equals("tempname", call_order[1])
      assert.equals("bufadd", call_order[2])
      assert.equals("bufload", call_order[3])
      assert.equals("set_lines", call_order[4])
      assert.equals("set_option", call_order[5])
      assert.equals("set_buf", call_order[6])
      assert.equals("set_cursor", call_order[7])
    end)
  end)

  describe("edge cases", function()
    it("handle empty opts table", function()
      local path = temp.create_temp_file({})

      assert.is_string(path)
      assert.is_not_nil(path:find("%.txt$"))
    end)

    it("handle opts with only ext", function()
      local path = temp.create_temp_file({ ext = "md" })

      assert.is_string(path)
      assert.is_not_nil(path:find("%.md$"))
      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, {})
    end)

    it("handle opts with only content", function()
      local content = { "test content" }
      local path = temp.create_temp_file({ content = content })

      assert.is_string(path)
      assert.is_not_nil(path:find("%.txt$"))
      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)

    it("handle very long content", function()
      local content = {}
      for i = 1, 1000 do
        table.insert(content, "Line " .. i)
      end

      temp.create_temp_file({ content = content })

      assert.spy(vim_api_spy.nvim_buf_set_lines).was_called_with(42, 0, -1, false, content)
    end)
  end)
end)
