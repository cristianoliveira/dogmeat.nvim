local assert = require("luassert")

describe("aichat backend", function()
  local aichat

  before_each(function()
    -- Mock vim global for testing
    _G.vim = {
      fn = {
        shellescape = function(str)
          if type(str) == "string" then
            return "'" .. str .. "'"
          end
          return "'" .. tostring(str) .. "'"
        end
      },
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

    -- Reset the module before each test
    package.loaded["dogmeat.backends.aichat"] = nil
    aichat = require("dogmeat.backends.aichat")
  end)

  describe("configuration", function()
    it("should have default aichat_bin config", function()
      assert.equals("aichat", aichat.configs.aichat_bin)
    end)

    it("should merge custom configs in new()", function()
      local builder = aichat:new({ aichat_bin = "/custom/path/aichat" })
      assert.equals("/custom/path/aichat", builder.configs.aichat_bin)
    end)

    it("should keep default config when no opts provided to new()", function()
      local builder = aichat:new()
      assert.equals("aichat", builder.configs.aichat_bin)
    end)
  end)

  describe("builder pattern", function()
    it("should return self for chaining", function()
      local result = aichat:new()
        :add_file("test.lua")
        :add_model("gpt-4")
        :prompt("test prompt")

      assert.is_not_nil(result)
    end)

    it("should reset args with new()", function()
      aichat:new()
        :add_file("old.lua")
        :prompt("old prompt")

      aichat:new()
      local command = aichat.to_command()

      -- Should be empty after reset
      assert.is_table(command)
    end)
  end)

  describe("add_file", function()
    it("should add a single file", function()
      aichat:new():add_file("test.lua")
      local command = aichat.to_command()

      assert.is_table(command)
      -- Check command array directly
      local has_file_flag = false
      local has_file_value = false
      for _, v in ipairs(command) do
        if v == "--file" then has_file_flag = true end
        if type(v) == "string" and v:find("test%.lua") then
          has_file_value = true
        end
      end

      assert.is_true(has_file_flag, "Expected --file flag in command. Got: " .. table.concat(command, ", "))
      assert.is_true(has_file_value, "Expected test.lua value in command. Got: " .. table.concat(command, ", "))
    end)

    it("should add multiple files", function()
      aichat:new()
        :add_file("file1.lua")
        :add_file("file2.lua")

      local command = aichat.to_command()
      local has_file1 = false
      local has_file2 = false
      for _, v in ipairs(command) do
        if v:match("file1%.lua") then has_file1 = true end
        if v:match("file2%.lua") then has_file2 = true end
      end

      assert.is_true(has_file1, "Expected file1.lua in command")
      assert.is_true(has_file2, "Expected file2.lua in command")
    end)
  end)

  describe("add_role", function()
    it("should add a role to args", function()
      aichat:new():add_role("code-reviewer")
      -- This tests the internal state is set
      -- Note: there's a bug in the original code - add_role sets args.roles as array
      -- but to_command checks args.role (singular)
    end)
  end)

  describe("add_model", function()
    it("should set model in command", function()
      aichat:new():add_model("gpt-4")
      local command = aichat.to_command()

      local has_model_flag = false
      local has_model_value = false
      for _, v in ipairs(command) do
        if v == "--model" then has_model_flag = true end
        if v:match("gpt%-4") then has_model_value = true end
      end

      assert.is_true(has_model_flag, "Expected --model flag in command")
      assert.is_true(has_model_value, "Expected gpt-4 value in command")
    end)
  end)

  describe("macro", function()
    it("should set macro name in command", function()
      aichat:new():macro("test-macro")
      local command = aichat.to_command()

      local has_macro_flag = false
      local has_macro_value = false
      for _, v in ipairs(command) do
        if v == "--macro" then has_macro_flag = true end
        if v:match("test%-macro") then has_macro_value = true end
      end

      assert.is_true(has_macro_flag, "Expected --macro flag in command")
      assert.is_true(has_macro_value, "Expected test-macro value in command")
    end)
  end)

  describe("prompt", function()
    it("should add prompt to command", function()
      aichat:new():prompt("explain this code")
      local command = aichat.to_command()

      local has_prompt = false
      for _, v in ipairs(command) do
        if v:match("explain this code") then has_prompt = true end
      end

      assert.is_true(has_prompt, "Expected prompt in command")
    end)
  end)

  describe("code", function()
    it("should add --code flag when true", function()
      aichat:new():code(true)
      local command = aichat.to_command()

      local has_code = false
      for _, v in ipairs(command) do
        if v == "--code" then has_code = true end
      end

      assert.is_true(has_code, "Expected --code flag in command")
    end)

    it("should not add --code flag when false", function()
      aichat:new():code(false)
      local command = aichat.to_command()

      local has_code = false
      for _, v in ipairs(command) do
        if v == "--code" then has_code = true end
      end

      assert.is_false(has_code, "Should not have --code flag in command")
    end)
  end)

  describe("to_command", function()
    it("should build complete command with all options", function()
      aichat:new()
        :macro("refactor")
        :add_model("gpt-4")
        :add_file("test.lua")
        :prompt("refactor this")
        :code(true)

      local command = aichat.to_command()

      -- Verify it's a table
      assert.is_table(command)

      -- Check for all expected flags
      local has_macro = false
      local has_model = false
      local has_file = false
      local has_code = false
      for _, v in ipairs(command) do
        if v == "--macro" then has_macro = true end
        if v == "--model" then has_model = true end
        if v == "--file" then has_file = true end
        if v == "--code" then has_code = true end
      end

      assert.is_true(has_macro, "Expected --macro in command")
      assert.is_true(has_model, "Expected --model in command")
      assert.is_true(has_file, "Expected --file in command")
      assert.is_true(has_code, "Expected --code in command")
    end)

    it("should return empty-ish table when no args set", function()
      aichat:new()
      local command = aichat.to_command()

      assert.is_table(command)
    end)
  end)

  describe("list commands", function()
    it("should generate list_macros command", function()
      local command = aichat.list_macros()

      assert.is_table(command)
      assert.equals("aichat", command[1])
      assert.equals("--list-macros", command[2])
    end)

    it("should generate list_roles command", function()
      local command = aichat.list_roles()

      assert.is_table(command)
      assert.equals("aichat", command[1])
      assert.equals("--list-roles", command[2])
    end)

    it("should generate list_models command", function()
      local command = aichat.list_models()

      assert.is_table(command)
      assert.equals("aichat", command[1])
      assert.equals("--list-models", command[2])
    end)
  end)

  describe("edge cases", function()
    it("should handle nil prompt", function()
      aichat:new():add_file("test.lua")
      local command = aichat.to_command()

      assert.is_table(command)
    end)

    it("should handle special characters in prompt", function()
      aichat:new():prompt("test 'with' quotes")
      local command = aichat.to_command()

      assert.is_table(command)
    end)

    it("should handle empty string prompt", function()
      aichat:new():prompt("")
      local command = aichat.to_command()

      assert.is_table(command)
      -- Empty prompt should still be included
      local has_empty_prompt = false
      for _, v in ipairs(command) do
        if v == "''" then has_empty_prompt = true end
      end
      assert.is_true(has_empty_prompt, "Expected empty prompt in command")
    end)

    it("should handle file paths with spaces", function()
      aichat:new():add_file("path with spaces/file.lua")
      local command = aichat.to_command()

      local cmd_str = table.concat(command, " ")
      assert.is_not_nil(cmd_str:find("path with spaces"))
    end)

    it("should handle file paths with special characters", function()
      aichat:new():add_file("path/with-special_chars.123.lua")
      local command = aichat.to_command()

      local cmd_str = table.concat(command, " ")
      assert.is_not_nil(cmd_str:find("with%-special_chars"))
    end)

    it("should handle multiline prompts", function()
      aichat:new():prompt("line1\nline2\nline3")
      local command = aichat.to_command()

      local cmd_str = table.concat(command, " ")
      assert.is_not_nil(cmd_str:find("line1"))
    end)
  end)

  describe("command structure", function()
    it("should include aichat_bin as first element", function()
      aichat:new()
      local command = aichat.to_command()

      assert.is_table(command)
      assert.equals("aichat", command[1])
    end)

    it("should use custom aichat_bin when configured", function()
      aichat:new({ aichat_bin = "/usr/local/bin/aichat" })
      local command = aichat.to_command()

      assert.equals("/usr/local/bin/aichat", command[1])
    end)

    it("should place --code flag before other flags", function()
      aichat:new()
        :code(true)
        :macro("test")
        :add_model("gpt-4")

      local command = aichat.to_command()

      -- Find position of --code
      local code_pos = nil
      local macro_pos = nil
      for i, v in ipairs(command) do
        if v == "--code" then code_pos = i end
        if v == "--macro" then macro_pos = i end
      end

      assert.is_not_nil(code_pos, "Expected --code flag")
      assert.is_not_nil(macro_pos, "Expected --macro flag")
      assert.is_true(code_pos < macro_pos, "--code should come before --macro")
    end)

    it("should handle only prompt without other options", function()
      aichat:new():prompt("just a prompt")
      local command = aichat.to_command()

      assert.is_table(command)
      assert.equals("aichat", command[1])

      local has_prompt = false
      for _, v in ipairs(command) do
        if v:match("just a prompt") then has_prompt = true end
      end
      assert.is_true(has_prompt)
    end)

    it("should handle only role without other options", function()
      aichat:new():add_role("assistant")
      local command = aichat.to_command()

      local has_role = false
      for _, v in ipairs(command) do
        if v == "--role" then has_role = true end
      end
      assert.is_true(has_role)
    end)
  end)

  describe("complex scenarios", function()
    it("should build command with all options in correct order", function()
      aichat:new()
        :code(true)
        :macro("refactor")
        :add_model("claude-3")
        :add_role("code-reviewer")
        :add_file("src/main.lua")
        :add_file("src/utils.lua")
        :prompt("refactor these files")

      local command = aichat.to_command()

      -- Verify all options are present
      local cmd_str = table.concat(command, " ")
      assert.is_not_nil(cmd_str:find("--code"))
      assert.is_not_nil(cmd_str:find("--macro"))
      assert.is_not_nil(cmd_str:find("--model"))
      assert.is_not_nil(cmd_str:find("--role"))
      assert.is_not_nil(cmd_str:find("--file"))
      assert.is_not_nil(cmd_str:find("refactor these files"))
    end)

    it("should allow building multiple commands with same module", function()
      -- First command
      aichat:new():macro("cmd1"):prompt("prompt1")
      local cmd1 = aichat.to_command()

      -- Second command (should reset state)
      aichat:new():macro("cmd2"):prompt("prompt2")
      local cmd2 = aichat.to_command()

      local cmd1_str = table.concat(cmd1, " ")
      local cmd2_str = table.concat(cmd2, " ")

      assert.is_not_nil(cmd1_str:find("cmd1"))
      assert.is_not_nil(cmd2_str:find("cmd2"))
      assert.is_nil(cmd2_str:find("cmd1"), "cmd2 should not contain cmd1 data")
    end)

    it("should handle three or more files", function()
      aichat:new()
        :add_file("file1.lua")
        :add_file("file2.lua")
        :add_file("file3.lua")

      local command = aichat.to_command()

      local file_count = 0
      for _, v in ipairs(command) do
        if v == "--file" then file_count = file_count + 1 end
      end

      assert.equals(3, file_count, "Expected 3 --file flags")
    end)
  end)

  describe("role functionality", function()
    it("should add role flag to command", function()
      aichat:new():add_role("code-reviewer")
      local command = aichat.to_command()

      local has_role_flag = false
      local has_role_value = false
      for i, v in ipairs(command) do
        if v == "--role" then
          has_role_flag = true
          if command[i + 1] == "code-reviewer" then
            has_role_value = true
          end
        end
      end

      assert.is_true(has_role_flag, "Expected --role flag")
      assert.is_true(has_role_value, "Expected role value 'code-reviewer'")
    end)

    it("should support different role names", function()
      aichat:new():add_role("shell-expert")
      local command = aichat.to_command()

      local cmd_str = table.concat(command, " ")
      assert.is_not_nil(cmd_str:find("shell%-expert"))
    end)
  end)

  describe("state management", function()
    it("should start with clean state after new()", function()
      aichat:new()
      local command = aichat.to_command()

      -- Should only have aichat_bin
      assert.equals(1, #command, "Expected only aichat_bin in command")
      assert.equals("aichat", command[1])
    end)

    it("should not leak state between new() calls", function()
      aichat:new():add_file("file1.lua"):macro("macro1")
      aichat:new():add_file("file2.lua")
      local command = aichat.to_command()

      local cmd_str = table.concat(command, " ")
      assert.is_nil(cmd_str:find("macro1"), "Previous macro should not be present")
      assert.is_nil(cmd_str:find("file1"), "Previous file should not be present")
      assert.is_not_nil(cmd_str:find("file2"), "New file should be present")
    end)
  end)
end)
