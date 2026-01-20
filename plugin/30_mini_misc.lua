local session_center = vim.g.session_center

local pack = require("util.pack")

pack.now(function()
  local MiniMisc = require("mini.misc")

  MiniMisc.setup_restore_cursor({ center = session_center })
  MiniMisc.setup_termbg_sync()
end)
