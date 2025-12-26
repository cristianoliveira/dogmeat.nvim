local assert = require("luassert")

describe("skills", function()
  local skills

  describe("list_macros", function()
    before_each(function()
        local list = {
          "amacro1",
          "foomacro2",
          "barmacro3",
        }

        -- Mock aichat
        local aichat_mock = {
          list_macros = function() return list end
        }

        -- Mock runner
        local runner_mock = {
          execute = function(_) return list end
        }

        package.loaded["dogmeat.backends.aichat"] = aichat_mock
        package.loaded["dogmeat.common.runner"] = runner_mock
        skills = require("dogmeat.skills")
    end)

    it("returns macros that match partial and sort alphabetically", function()
      local result = skills.list_macros("macro")
      assert.is_table(result)
      assert.equals(3, #result)
      assert.equals("amacro1", result[1])
      assert.equals("barmacro3", result[2])
      assert.equals("foomacro2", result[3])

      local res2 = skills.list_macros("macro2")
      assert.is_table(res2)
      assert.equals(1, #res2)
      assert.equals("foomacro2", res2[1])
    end)

    it("returns all macros when partial is nil and sort alphabetically", function()
      local result = skills.list_macros()
      assert.is_table(result)
      assert.equals(3, #result)
      assert.equals("amacro1", result[1])
      assert.equals("barmacro3", result[2])
      assert.equals("foomacro2", result[3])
    end)
  end)
end)
