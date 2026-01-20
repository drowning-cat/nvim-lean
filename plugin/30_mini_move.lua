local pack = require("util.pack")

pack.later(function()
  local MiniMove = require("mini.move")

  MiniMove.setup({
    mappings = {
      left = "<C-h>",
      down = "<C-j>",
      up = "<C-k>",
      right = "<C-l>",
      line_left = "",
      line_down = "",
      line_up = "",
      line_right = "",
    },
  })
end)
