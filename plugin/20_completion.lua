local pack = require("util.pack")

pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = "main" },
})

pack.later(function()
  require("blink.cmp").setup({
    keymap = {
      ["<C-n>"] = { "show_and_insert", "select_next" },
      ["<C-p>"] = { "show_and_insert", "select_prev" },
      ["<C-j>"] = { "select_and_accept" },
    },
    cmdline = {
      keymap = { ["<Right>"] = false, ["<Left>"] = false },
      completion = {
        menu = { auto_show = true },
        list = { selection = { preselect = false } },
      },
    },
  })

  vim.keymap.set("i", "<C-x><C-o>", function()
    require("blink.cmp").show()
    require("blink.cmp").show_documentation()
    require("blink.cmp").hide_documentation()
  end, { desc = "Show completion" })
end)
