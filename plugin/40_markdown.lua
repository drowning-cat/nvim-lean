local pack = require("util.pack")

pack.add({
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

pack.now(function()
  require("render-markdown").setup({
    checkbox = { enabled = false },
    code = { sign = false, width = "full" },
    heading = { icons = {} },
  })
end)
