if vim.fn.has("nvim-0.12") == 0 then
  return vim.notify("Install Neovim 0.12+", vim.log.levels.ERROR)
end

-- NOTE: See `plugin/` folder
