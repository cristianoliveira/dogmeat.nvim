local assert = require("luassert")

describe("dogmeat configs", function()
  local configs

  before_each(function()
    -- Mock vim global for testing
    _G.vim = {
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

    -- Reset module
    package.loaded["dogmeat.configs"] = nil
    configs = require("dogmeat.configs")
  end)

  describe("default configuration", function()
    it("should export default config", function()
      assert.is_not_nil(configs.default)
      assert.is_table(configs.default)
    end)

    it("should have aichat_bin default", function()
      assert.equals("aichat", configs.default.aichat_bin)
    end)

    it("should have empty roles table", function()
      assert.is_table(configs.default.roles)
    end)

    it("should have empty macros table", function()
      assert.is_table(configs.default.macros)
    end)
  end)

  describe("setup function", function()
    it("should return a config object", function()
      local result = configs.setup({})
      assert.is_table(result)
    end)

    it("should merge with defaults", function()
      local result = configs.setup({
        aichat_bin = "/custom/aichat"
      })

      assert.equals("/custom/aichat", result.aichat_bin)
      assert.is_table(result.roles)
      assert.is_table(result.macros)
    end)

    it("should deep merge nested tables", function()
      local result = configs.setup({
        roles = {
          reviewer = "code-reviewer",
          assistant = "assistant"
        }
      })

      assert.equals("code-reviewer", result.roles.reviewer)
      assert.equals("assistant", result.roles.assistant)
      assert.equals("aichat", result.aichat_bin)
    end)

    it("should handle nil opts gracefully", function()
      local result = configs.setup(nil)

      assert.equals("aichat", result.aichat_bin)
      assert.is_table(result.roles)
      assert.is_table(result.macros)
    end)

    it("should handle empty opts", function()
      local result = configs.setup({})

      assert.equals("aichat", result.aichat_bin)
      assert.is_table(result.roles)
      assert.is_table(result.macros)
    end)

    it("should preserve all defaults when only partial config provided", function()
      local result = configs.setup({
        macros = { test = "test-macro" }
      })

      assert.equals("aichat", result.aichat_bin)
      assert.is_table(result.roles)
      assert.equals("test-macro", result.macros.test)
    end)

    it("should allow multiple roles", function()
      local result = configs.setup({
        roles = {
          role1 = "description1",
          role2 = "description2",
          role3 = "description3"
        }
      })

      assert.equals("description1", result.roles.role1)
      assert.equals("description2", result.roles.role2)
      assert.equals("description3", result.roles.role3)
    end)

    it("should allow multiple macros", function()
      local result = configs.setup({
        macros = {
          macro1 = "cmd1",
          macro2 = "cmd2",
          macro3 = "cmd3"
        }
      })

      assert.equals("cmd1", result.macros.macro1)
      assert.equals("cmd2", result.macros.macro2)
      assert.equals("cmd3", result.macros.macro3)
    end)

    it("should not modify the default config", function()
      local original_bin = configs.default.aichat_bin

      configs.setup({
        aichat_bin = "/modified/path"
      })

      -- Default should remain unchanged
      assert.equals(original_bin, configs.default.aichat_bin)
    end)

    it("should handle complex nested configuration", function()
      local result = configs.setup({
        aichat_bin = "/usr/bin/aichat",
        roles = {
          dev = "developer role",
          reviewer = "code reviewer role"
        },
        macros = {
          refactor = "refactor code",
          test = "write tests"
        }
      })

      assert.equals("/usr/bin/aichat", result.aichat_bin)
      assert.equals("developer role", result.roles.dev)
      assert.equals("code reviewer role", result.roles.reviewer)
      assert.equals("refactor code", result.macros.refactor)
      assert.equals("write tests", result.macros.test)
    end)
  end)

  describe("edge cases", function()
    it("should handle config with only aichat_bin", function()
      local result = configs.setup({
        aichat_bin = "/only/bin/path"
      })

      assert.equals("/only/bin/path", result.aichat_bin)
      assert.is_table(result.roles)
      assert.is_table(result.macros)
    end)

    it("should handle config with only roles", function()
      local result = configs.setup({
        roles = { test = "test-role" }
      })

      assert.equals("aichat", result.aichat_bin)
      assert.equals("test-role", result.roles.test)
      assert.is_table(result.macros)
    end)

    it("should handle config with only macros", function()
      local result = configs.setup({
        macros = { test = "test-macro" }
      })

      assert.equals("aichat", result.aichat_bin)
      assert.is_table(result.roles)
      assert.equals("test-macro", result.macros.test)
    end)
  end)
end)
