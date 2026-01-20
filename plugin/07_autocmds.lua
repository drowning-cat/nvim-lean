vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanking text",
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Pack update

local pack_au = vim.api.nvim_create_augroup("pack_update", { clear = true })
local pack_autocmd = function(pattern, callback)
  vim.api.nvim_create_autocmd("PackChanged", {
    pattern = pattern,
    desc = string.format("Update `%s` after pack update", pattern),
    group = pack_au,
    callback = callback,
  })
end

pack_autocmd("nvim-treesitter", function(e)
  local kind = e.data.kind
  if kind == "update" then
    require("nvim-treesitter").update()
  end
end)

pack_autocmd("blink.cmp", function(e)
  local kind, name, verison = e.data.kind, e.data.spec.name, e.data.spec.version
  if verison == "main" and (kind == "install" or kind == "update") then
    vim.cmd.packadd({ args = { name }, bang = false })
    vim.defer_fn(function()
      require("blink.cmp.fuzzy.build").build()
    end, 200)
  end
end)
