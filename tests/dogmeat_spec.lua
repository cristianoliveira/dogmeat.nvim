local assert = require("luassert")

describe("dogmeat", function()
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

    -- Reset the module before each test
    package.loaded["dogmeat"] = nil
    dogmeat = require("dogmeat")
  end)

  describe("setup", function()
    it("should initialize with default config", function()
      dogmeat.setup()
      assert.is_not_nil(dogmeat.config)
      assert.equals("aichat", dogmeat.config.aichat_cmd)
    end)

    it("should merge user config with defaults", function()
      dogmeat.setup({
        aichat_cmd = "custom-aichat"
      })
      assert.equals("custom-aichat", dogmeat.config.aichat_cmd)
    end)

    it("should preserve default values when not overridden", function()
      dogmeat.setup({
        roles = { test = "test_role" }
      })
      assert.equals("aichat", dogmeat.config.aichat_cmd)
      assert.equals("test_role", dogmeat.config.roles.test)
    end)
  end)

  describe("config", function()
    it("should have default aichat_cmd", function()
      assert.equals("aichat", dogmeat.config.aichat_cmd)
    end)

    it("should have empty roles table by default", function()
      assert.is_table(dogmeat.config.roles)
    end)

    it("should have empty macros table by default", function()
      assert.is_table(dogmeat.config.macros)
    end)
  end)
end)
