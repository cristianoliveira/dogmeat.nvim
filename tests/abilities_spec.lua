local assert = require("luassert")
local spy = require("luassert.spy")
local stub = require("luassert.stub")

describe("abilities", function()
  local abilities
  local aichat_mock
  local runner_mock
  local editor_mock

  before_each(function()
    -- Mock vim.inspect
    _G.vim = {
      inspect = function(obj) return tostring(obj) end
    }

    -- Create aichat builder mock
    local builder_instance = {
      add_file = spy.new(function(self) return self end),
      code = spy.new(function(self) return self end),
      prompt = spy.new(function(self) return self end),
      to_command = spy.new(function() return { "aichat", "--code" } end)
    }

    aichat_mock = {
      new = spy.new(function()
        return builder_instance
      end)
    }

    -- Mock runner
    runner_mock = {
      async = spy.new(function() end)
    }

    -- Mock editor
    editor_mock = {
      tmp_markdown_file = spy.new(function() end)
    }

    -- Setup package mocks
    package.loaded["dogmeat.backends.aichat"] = aichat_mock
    package.loaded["dogmeat.common.runner"] = runner_mock
    package.loaded["dogmeat.common.editor"] = editor_mock

    -- Reset and load abilities module
    package.loaded["dogmeat.abilities"] = nil
    abilities = require("dogmeat.abilities")
  end)

  after_each(function()
    -- Clean up mocks
    package.loaded["dogmeat.backends.aichat"] = nil
    package.loaded["dogmeat.common.runner"] = nil
    package.loaded["dogmeat.common.editor"] = nil
    package.loaded["dogmeat.abilities"] = nil
  end)

  describe("module structure", function()
    it("should export fetch_code function", function()
      assert.is_function(abilities.fetch_code)
    end)

    it("should export fetch_code_with_instruction function", function()
      assert.is_function(abilities.fetch_code_with_instruction)
    end)
  end)

  describe("fetch_code", function()
    it("should require on_finish callback", function()
      local result = abilities.fetch_code({
        current_file = "/path/to/file.lua"
      })

      assert.is_nil(result)
      assert.spy(editor_mock.tmp_markdown_file).was_not_called()
    end)

    it("should accept valid options", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      assert.is_not_nil(aichat_mock.new)
    end)

    it("should create aichat builder with current_file", function()
      local on_finish = spy.new(function() end)
      local builder_instance = nil

      aichat_mock.new = spy.new(function()
        builder_instance = {
          add_file = spy.new(function(self, file)
            return self
          end),
          code = spy.new(function(self) return self end),
          prompt = spy.new(function(self) return self end),
          to_command = spy.new(function() return { "aichat" } end)
        }
        return builder_instance
      end)

      package.loaded["dogmeat.backends.aichat"] = aichat_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      assert.spy(aichat_mock.new).was_called()
      assert.spy(builder_instance.add_file).was_called_with(builder_instance, "/path/to/file.lua")
      assert.spy(builder_instance.code).was_called_with(builder_instance, true)
    end)

    it("should call editor.tmp_markdown_file", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      assert.spy(editor_mock.tmp_markdown_file).was_called()
    end)

    it("should handle editor callback with instructions", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil

      editor_mock.tmp_markdown_file = spy.new(function(cb)
        editor_callback = cb
      end)

      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      -- Simulate editor callback
      assert.is_function(editor_callback)
      editor_callback({
        path = "/tmp/instructions.md",
        content = "Refactor this code"
      })

      assert.spy(runner_mock.async).was_called()
    end)

    it("should not proceed if instructions file is missing", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil

      editor_mock.tmp_markdown_file = spy.new(function(cb)
        editor_callback = cb
      end)

      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
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

    it("should not proceed if content is missing", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil

      editor_mock.tmp_markdown_file = spy.new(function(cb)
        editor_callback = cb
      end)

      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      -- Simulate editor callback with no content
      editor_callback({
        path = "/tmp/instructions.md",
        content = nil
      })

      assert.spy(runner_mock.async).was_not_called()
    end)

    it("should build correct prompt with file paths", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local builder_instance = {
        add_file = spy.new(function(self) return self end),
        code = spy.new(function(self) return self end),
        prompt = spy.new(function(self) return self end),
        to_command = spy.new(function() return { "aichat" } end)
      }

      aichat_mock.new = spy.new(function() return builder_instance end)
      editor_mock.tmp_markdown_file = spy.new(function(cb) editor_callback = cb end)

      package.loaded["dogmeat.backends.aichat"] = aichat_mock
      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      editor_callback({
        path = "/tmp/instructions.md",
        content = "Refactor this code"
      })

      -- Should call prompt with file paths included
      assert.spy(builder_instance.prompt).was_called()
      assert.spy(builder_instance.add_file).was_called(2) -- current_file and instructions_file
    end)

    it("should call on_finish with success result", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local runner_callbacks = nil

      editor_mock.tmp_markdown_file = spy.new(function(cb) editor_callback = cb end)
      runner_mock.async = spy.new(function(cmd, cbs) runner_callbacks = cbs end)

      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
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
        path = "/tmp/instructions.md",
        content = "refactored code"
      })
    end)

    it("should call on_finish with errors on non-zero exit code", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local runner_callbacks = nil

      editor_mock.tmp_markdown_file = spy.new(function(cb) editor_callback = cb end)
      runner_mock.async = spy.new(function(cmd, cbs) runner_callbacks = cbs end)

      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
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

    it("should call on_finish with errors on runner error", function()
      local on_finish = spy.new(function() end)
      local editor_callback = nil
      local runner_callbacks = nil

      editor_mock.tmp_markdown_file = spy.new(function(cb) editor_callback = cb end)
      runner_mock.async = spy.new(function(cmd, cbs) runner_callbacks = cbs end)

      package.loaded["dogmeat.common.editor"] = editor_mock
      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code({
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

  describe("fetch_code_with_instruction", function()
    it("should require on_finish callback", function()
      local result = abilities.fetch_code_with_instruction({
        current_file = "/path/to/file.lua",
        instruction = "Refactor this"
      })

      assert.is_nil(result)
    end)

    it("should require instruction", function()
      local on_finish = spy.new(function() end)

      local result = abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua"
      })

      assert.is_nil(result)
      assert.spy(runner_mock.async).was_not_called()
    end)

    it("should create aichat command with instruction", function()
      local on_finish = spy.new(function() end)
      local builder_instance = {
        add_file = spy.new(function(self) return self end),
        code = spy.new(function(self) return self end),
        prompt = spy.new(function(self) return self end),
        to_command = spy.new(function() return { "aichat" } end)
      }

      aichat_mock.new = spy.new(function() return builder_instance end)

      package.loaded["dogmeat.backends.aichat"] = aichat_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      assert.spy(builder_instance.add_file).was_called_with(builder_instance, "/path/to/file.lua")
      assert.spy(builder_instance.code).was_called_with(builder_instance, true)
      assert.spy(builder_instance.to_command).was_called()
    end)

    it("should not call editor.tmp_markdown_file", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      assert.spy(editor_mock.tmp_markdown_file).was_not_called()
    end)

    it("should call runner.async immediately", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      assert.spy(runner_mock.async).was_called()
    end)

    it("should call on_finish with success result", function()
      local on_finish = spy.new(function() end)
      local runner_callbacks = nil

      runner_mock.async = spy.new(function(cmd, cbs)
        runner_callbacks = cbs
      end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      -- Simulate successful runner callback
      runner_callbacks.on_success(0, { stdout = "refactored code", stderr = "" })

      assert.spy(on_finish).was_called()
      assert.spy(on_finish).was_called_with({
        content = "refactored code"
      })
    end)

    it("should call on_finish with errors on non-zero exit code", function()
      local on_finish = spy.new(function() end)
      local runner_callbacks = nil

      runner_mock.async = spy.new(function(cmd, cbs)
        runner_callbacks = cbs
      end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      -- Simulate failed runner callback
      runner_callbacks.on_success(1, { stdout = "error output", stderr = "error details" })

      assert.spy(on_finish).was_called()
      local call_args = on_finish.calls[1].refs[1]
      assert.is_table(call_args.errors)
    end)

    it("should call on_finish with errors on runner error", function()
      local on_finish = spy.new(function() end)
      local runner_callbacks = nil

      runner_mock.async = spy.new(function(cmd, cbs)
        runner_callbacks = cbs
      end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      -- Simulate error callback
      runner_callbacks.on_error("stderr error", {})

      assert.spy(on_finish).was_called()
      local call_args = on_finish.calls[1].refs[1]
      assert.is_table(call_args.errors)
      assert.equals("stderr error", call_args.errors[1])
    end)

    it("should return result from runner.async", function()
      local expected_result = { some = "value" }
      runner_mock.async = spy.new(function() return expected_result end)

      package.loaded["dogmeat.common.runner"] = runner_mock
      package.loaded["dogmeat.abilities"] = nil
      abilities = require("dogmeat.abilities")

      local result = abilities.fetch_code_with_instruction({
        on_finish = function() end,
        current_file = "/path/to/file.lua",
        instruction = "Refactor this code"
      })

      assert.equals(expected_result, result)
    end)
  end)

  describe("edge cases", function()
    it("should handle empty current_file in fetch_code", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = ""
      })

      assert.spy(editor_mock.tmp_markdown_file).was_called()
    end)

    it("should handle nil current_file in fetch_code", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code({
        on_finish = on_finish,
        current_file = nil
      })

      assert.spy(editor_mock.tmp_markdown_file).was_called()
    end)

    it("should handle special characters in instruction", function()
      local on_finish = spy.new(function() end)

      abilities.fetch_code_with_instruction({
        on_finish = on_finish,
        current_file = "/path/to/file.lua",
        instruction = "Refactor with 'quotes' and \"double quotes\""
      })

      assert.spy(runner_mock.async).was_called()
    end)
  end)
end)
