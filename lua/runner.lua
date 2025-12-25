-- runner.lua
-- Just a helper to run the plugin for development, to use it:
-- :source %
local dogmeat = require("dogmeat")

dogmeat.go_fetch_code({
  on_finish = function(resp)
    print(resp.path)
    print(resp.content)
  end,
  current_file = "/home/cristianoliveira/other/dogmeat.nvim/lua/dogmeat/init.lua"
})
