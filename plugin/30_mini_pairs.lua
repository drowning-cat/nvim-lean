local pack = require("util.pack")

pack.later(function()
  local MiniPairs = require("mini.pairs")

  MiniPairs.setup({
    -- modes = { command = true },
    mappings = {
      ["("] = { neigh_pattern = "[^\\][%s>)%]},:]" },
      ["["] = { neigh_pattern = "[^\\][%s>)%]},:]" },
      ["{"] = { neigh_pattern = "[^\\][%s>)%]},:]" },
      ['"'] = { neigh_pattern = "[%s<(%[{][%s>)%]},:]" },
      ["'"] = { neigh_pattern = "[%s<(%[{][%s>)%]},:]" },
      ["`"] = { neigh_pattern = "[%s<(%[{][%s>)%]},:]" },
      ["<"] = { action = "open", pair = "<>", neigh_pattern = "[\r%w\"'`].", register = { cr = false } },
      [">"] = { action = "close", pair = "<>", register = { cr = false } },
    },
  })
end)
