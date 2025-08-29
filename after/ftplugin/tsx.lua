local user_input = require("mini.surround").user_input
local surround_ts = require("mini.surround").gen_spec.input.treesitter
vim.b.minisurround_config = {
  custom_surroundings = {
    t = { input = surround_ts({ outer = "@tag.outer", inner = "@tag.inner" }) },
    T = {
      input = surround_ts({ outer = "@tag_name.outer", inner = "@tag_name.inner" }),
      output = function()
        local tag_name = user_input("Tag name")
        tag_name = tag_name .. " "
        return { left = tag_name, right = tag_name }
      end,
    },
  },
}
