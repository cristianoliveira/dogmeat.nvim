local assert = require("luassert")

describe("dogmeat init", function()
  local dogmeat

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

    -- Reset modules
    package.loaded["dogmeat.configs"] = nil
    package.loaded["dogmeat.abilities"] = nil
    package.loaded["dogmeat"] = nil
    dogmeat = require("dogmeat")
  end)

  describe("module structure", function()
    it("export configs", function()
      assert.is_not_nil(dogmeat.configs)
      assert.is_table(dogmeat.configs)
    end)

    it("export setup function", function()
      assert.is_function(dogmeat.setup)
    end)

    it("export abilities as 'go'", function()
      assert.is_not_nil(dogmeat.go)
      assert.is_table(dogmeat.go)
    end)
  end)

  describe("default configuration", function()
    it("have default aichat_bin", function()
      assert.equals("aichat", dogmeat.configs.aichat_bin)
    end)

    it("have empty roles table", function()
      assert.is_table(dogmeat.configs.roles)
      assert.equals(0, #dogmeat.configs.roles)
    end)

    it("have empty macros table", function()
      assert.is_table(dogmeat.configs.macros)
      assert.equals(0, #dogmeat.configs.macros)
    end)
  end)

  describe("setup", function()
    it("update configs when called", function()
      dogmeat.setup({
        aichat_bin = "/custom/aichat"
      })

      assert.equals("/custom/aichat", dogmeat.configs.aichat_bin)
    end)

    it("merge custom roles", function()
      dogmeat.setup({
        roles = {
          reviewer = "code-reviewer-role",
          assistant = "assistant-role"
        }
      })

      assert.is_table(dogmeat.configs.roles)
      assert.equals("code-reviewer-role", dogmeat.configs.roles.reviewer)
      assert.equals("assistant-role", dogmeat.configs.roles.assistant)
    end)

    it("merge custom macros", function()
      dogmeat.setup({
        macros = {
          refactor = "refactor-macro",
          test = "test-macro"
        }
      })

      assert.is_table(dogmeat.configs.macros)
      assert.equals("refactor-macro", dogmeat.configs.macros.refactor)
      assert.equals("test-macro", dogmeat.configs.macros.test)
    end)

    it("preserve defaults when not overridden", function()
      dogmeat.setup({
        roles = { custom = "custom-role" }
      })

      assert.equals("aichat", dogmeat.configs.aichat_bin)
      assert.is_table(dogmeat.configs.macros)
    end)

    it("handle empty opts", function()
      dogmeat.setup({})

      assert.equals("aichat", dogmeat.configs.aichat_bin)
      assert.is_table(dogmeat.configs.roles)
      assert.is_table(dogmeat.configs.macros)
    end)

    it("handle nil opts", function()
      dogmeat.setup()

      assert.equals("aichat", dogmeat.configs.aichat_bin)
      assert.is_table(dogmeat.configs.roles)
      assert.is_table(dogmeat.configs.macros)
    end)
  end)

  describe("abilities integration", function()
    it("provide fetch_code ability", function()
      assert.is_not_nil(dogmeat.go.fetch_code)
      assert.is_function(dogmeat.go.fetch_code)
    end)
  end)
end)
