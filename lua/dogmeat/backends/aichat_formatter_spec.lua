local formatter = require("dogmeat.backends.aichat_formatter")

describe("aichat formatter", function()
  describe("format_macro_output", function()
    local output = {
      ">> .role foo",
      ">> .file print('Hello world')",
      "Hello world",
      "Hello world again",
    }

    it("removes lines that do not start with >>", function()
      local result = formatter.format_macro_output(output)
      assert.is_table(result)
      assert.equals(2, #result)
      assert.equals("Hello world", result[1])
      assert.equals("Hello world again", result[2])
    end)

  end)
end)
