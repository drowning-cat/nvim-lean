local pack = require("util.pack")

pack.later(function()
  local MiniIndentscope = require("mini.indentscope")

  vim.g.miniindentscope_disable = true

  MiniIndentscope.setup({
    mappings = {
      object_scope = "ii",
      object_scope_with_border = "ai",
      goto_top = "[i",
      goto_bottom = "]i",
    },
    options = {
      indent_at_cursor = false,
    },
  })

  vim.keymap.set("n", "[I", "100[i", { remap = true, desc = "Indent first" })
  vim.keymap.set("n", "]I", "100]i", { remap = true, desc = "Indent last" })

  vim.keymap.set("n", "grs", function()
    vim.cmd("sil norm " .. string.rep("[i", vim.v.count - 1) .. "viiy']vaiopgv<")
  end, { desc = "Unscope" })
end)
