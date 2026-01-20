local pack = require("util.pack")

pack.add({
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/nvim-mini/mini.hues" },
})

-- Highlights

pack.now(function()
  vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "Set up custom highlights",
    group = vim.api.nvim_create_augroup("custom_highlights", { clear = true }),
    callback = function()
      local perf_bg = vim.api.nvim_get_hl(0, { name = "Indentifier", link = false }).fg
      vim.api.nvim_set_hl(0, "HipatternsPerf", { bold = true, fg = "black", bg = perf_bg })
      vim.api.nvim_set_hl(0, "LspProgress", { default = true, link = "Comment" })
    end,
  })

  require("tokyonight").setup({
    on_highlights = function(hl, c)
      hl.LspProgress = { fg = c.comment }
    end,
  })
end)

-- Persistent colors

pack.now(function()
  vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "Save the colorscheme in shada-persistent variables",
    group = vim.api.nvim_create_augroup("save_colors", { clear = true }),
    callback = function()
      vim.g.COLORS_NAME = vim.g.colors_name
      vim.g.COLORS_BG = vim.o.background
    end,
  })

  local set_colorscheme = function(bg, name)
    vim.o.background = bg
    vim.cmd.colorscheme({ name, mods = { silent = true } })
    return name == vim.g.colors_name
  end

  pcall(vim.cmd.rshada)
  if not set_colorscheme(vim.g.COLORS_BG, vim.g.COLORS_NAME) then
    set_colorscheme("dark", "tokyonight")
  end
end)
