local spy = require("luassert.spy")

describe("abilities", function()
  local abilities
  local runner_mock
  local editor_mock

  before_each(function()
    -- Mock vim global (required by aichat builder)
    _G.vim = {
      inspect = function(obj) return tostring(obj) end,
      fn = {
        shellescape = function(str) return "'" .. str .. "'" end,
        tempname = function() return "/tmp/nvim.test.tmp" end,
        bufadd = function(name) return 1 end,
        bufload = function(buf) end,
      },
      api = {
        nvim_create_augroup = function(name, opts) end,
        nvim_create_autocmd = function(event, opts) end,
        nvim_buf_set_option = function(buf, name, value) end,
        nvim_buf_set_lines = function(buf, start, finish, strict, lines) end,
        nvim_win_set_buf = function(win, buf) end,
        nvim_win_set_cursor = function(win, pos) end,
      },
      cmd = function(cmd) end,
      tbl_deep_extend = function(behavior, ...)
        local result = {}
        for _, tbl in ipairs({...}) do
          for k, v in pairs(tbl) do
            if type(v) == "table" and type(result[k]) == "table" then
              result[k] = vim.tbl_deep_extend(behavior, result[k], v)
            else
              result[k] = v
            end
          end
        end
        return result
      end
    }

    -- Mock runner (side effects: running shell commands)
    runner_mock = {
      async = spy.new(function() end)
    }

    -- Mock editor (side effects: opening vim windows)
    editor_mock = {
      temp = {
        markdown_file = spy.new(function() end)
      }
    }

    -- Setup package mocks (only external dependencies)
    package.loaded["dogmeat.common.runner"] = runner_mock
    package.loaded["dogmeat.editor"] = editor_mock

    -- Reset and load abilities module (uses real aichat builder, strings, formatter)
    package.loaded["dogmeat.backends.aichat"] = nil
    package.loaded["dogmeat.backends.aichat_formatter"] = nil
    package.loaded["dogmeat.abilities"] = nil
    abilities = require("dogmeat.abilities")
  end)

  after_each(function()
    -- Clean up mocks
    package.loaded["dogmeat.backends.aichat"] = nil
    package.loaded["dogmeat.common.runner"] = nil
    package.loaded["dogmeat.backends.aichat_formatter"] = nil
    package.loaded["dogmeat.editor"] = nil
    package.loaded["dogmeat.abilities"] = nil
  end)

  describe("fetch_with_markdown", function()
    it("returns nil when on_finish callback is missing", function()
      local result = abilities.fetch_with_markdown({
        current_file = "/path/to/file.lua"
      })

      assert.is_nil(result)
      assert.spy(editor_mock.temp.markdown_file).was_not_called()
    end)

    it("does not proceed if instructions file is missing", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil

      editor_mock.temp.markdown_file = spy.new(function(cb)
        editor_callback = cb
      end)

      package.loaded["dogmeat.editor"] = editor_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_markdown({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      -- Simulate editor callback with no path
      editor_callback({
        path = nil,
        content = "Refactor this code"
      })

      assert.spy(runner_mock.async).was_not_called()
    end)

    it("calls on_finish with success result when code is 1", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local runner_callbacks = nil

      editor_mock.temp.markdown_file = spy.new(function(cb) editor_callback = cb end)
      editor_mock.temp.create_temp_file = spy.new(function(cb) return "/tmp/tmpfile.txt" end)
      runner_mock.async = spy.new(function(cmd, cbs) runner_callbacks = cbs end)

      package.loaded["dogmeat.editor"] = editor_mock
      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_markdown({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      editor_callback({
        path = "/tmp/instructions.md",
        content = "Refactor this code"
      })

      -- Simulate successful runner callback
      runner_callbacks.on_success(0, { stdout = "refactored code", stderr = "" })

      assert.spy(on_finish).was_called()
      assert.spy(on_finish).was_called_with({
        content = { "refactored code" },
        path = "/tmp/tmpfile.txt",
      })
    end)

    it("calls on_finish with errors when code is non-zero", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local runner_callbacks = nil

      editor_mock.temp.markdown_file = spy.new(function(cb) editor_callback = cb end)
      runner_mock.async = spy.new(function(cmd, cbs) runner_callbacks = cbs end)

      package.loaded["dogmeat.editor"] = editor_mock
      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_markdown({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      editor_callback({
        path = "/tmp/instructions.md",
        content = "Refactor this code"
      })

      -- Simulate failed runner callback
      runner_callbacks.on_success(1, { stdout = "error output", stderr = "error details" })

      assert.spy(on_finish).was_called()
      local call_args = on_finish.calls[1].refs[1]
      assert.is_table(call_args.errors)
    end)

    it("calls on_finish with errors on runner error", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local runner_callbacks = nil

      editor_mock.temp.markdown_file = spy.new(function(cb) editor_callback = cb end)
      runner_mock.async = spy.new(function(cmd, cbs) runner_callbacks = cbs end)

      package.loaded["dogmeat.editor"] = editor_mock
      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_markdown({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      editor_callback({
        path = "/tmp/instructions.md",
        content = "Refactor this code"
      })

      -- Simulate error callback
      runner_callbacks.on_error("stderr error", {})

      assert.spy(on_finish).was_called()
      local call_args = on_finish.calls[1].refs[1]
      assert.is_table(call_args.errors)
      assert.equals("stderr error", call_args.errors[1])
    end)
  end)

  describe("fetch_with_instructions", function()
    it("returns nil when on_finish callback is missing", function()
      local result = abilities.fetch_with_instructions("Refactor this", {
        current_file = "/path/to/file.lua"
      })

      assert.is_nil(result)
    end)

    it("calls on_finish with success result when code is 0", function()
      local on_finish = spy.new(function() end)
      local runner_callbacks = nil

      runner_mock.async = spy.new(function(cmd, cbs)
        runner_callbacks = cbs
      end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_instructions("Refactor this code", {
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      -- Simulate successful runner callback
      runner_callbacks.on_success(0, { stdout = "refactored code", stderr = "" })

      assert.spy(on_finish).was_called()
      assert.spy(on_finish).was_called_with({
        content = { "refactored code" }
      })
    end)

    it("calls on_finish with errors when code is non-zero", function()
      local on_finish = spy.new(function() end)
      local runner_callbacks = nil

      runner_mock.async = spy.new(function(cmd, cbs)
        runner_callbacks = cbs
      end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_instructions("Refactor this code", {
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      -- Simulate failed runner callback
      runner_callbacks.on_success(1, { stdout = "error output", stderr = "error details" })

      assert.spy(on_finish).was_called()
      local call_args = on_finish.calls[1].refs[1]
      assert.is_table(call_args.errors)
    end)

    it("calls on_finish with errors on runner error", function()
      local on_finish = spy.new(function() end)
      local runner_callbacks = nil

      runner_mock.async = spy.new(function(cmd, cbs)
        runner_callbacks = cbs
      end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_with_instructions("Refactor this code", {
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      -- Simulate error callback
      runner_callbacks.on_error("stderr error", {})

      assert.spy(on_finish).was_called()
      local call_args = on_finish.calls[1].refs[1]
      assert.is_table(call_args.errors)
      assert.equals("stderr error", call_args.errors[1])
    end)
  end)
end)
