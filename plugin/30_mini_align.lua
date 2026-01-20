local pack = require("util.pack")

pack.later(function()
  local MiniAlign = require("mini.align")

  MiniAlign.setup({
    mappings = {
      start = "",
      start_with_preview = "g|",
    },
    modifiers = {
      k = function(_, opts)
        local cycle_rev = { none = "right", right = "center", center = "left", left = "right" }
        opts.justify_side = cycle_rev[opts.justify_side] or "right"
      end,
      j = function(_, opts)
        local cycle = { none = "left", left = "center", center = "right", right = "left" }
        opts.justify_side = cycle[opts.justify_side] or "left"
      end,
      n = function(_, opts)
        opts.justify_side = "none"
      end,
    },
  })
end)
