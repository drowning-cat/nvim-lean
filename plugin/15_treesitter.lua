local ts_install = vim.g.ts_install or {}

local pack = require("util.pack")

pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
})

pack.now(function()
  vim.treesitter.language.register("tsx", "typescriptreact")

  local ts_filetypes = vim
    .iter(ts_install)
    :map(function(lang)
      return vim.treesitter.language.get_filetypes(lang)
    end)
    :flatten()
    :totable()

  require("nvim-treesitter").install(ts_install)

  vim.api.nvim_create_autocmd("FileType", {
    desc = "Setup treesitter for a buffer",
    pattern = ts_filetypes,
    group = vim.api.nvim_create_augroup("ts_setup", { clear = true }),
    callback = function(e)
      vim.treesitter.start(e.buf)
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })

  local ts_swap = require("nvim-treesitter-textobjects.swap")
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>a", function() ts_swap.swap_next("@parameter.inner") end, { desc = "Swap arg next" })
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>A", function() ts_swap.swap_previous("@parameter.inner") end, { desc = "Swap arg prev" })
end)
