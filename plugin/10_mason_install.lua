local mason_install = vim.g.mason_install or {}

local pack = require("util.pack")

pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
})

pack.now(function()
  require("mason").setup()

  local mason_available = require("mason-registry").get_installed_package_names()
  local mason_rest = {}
  for _, inst in ipairs(mason_install) do
    if not vim.list_contains(mason_available, inst) then
      table.insert(mason_rest, inst)
    end
  end
  if #mason_rest > 0 then
    vim.cmd("MasonInstall " .. table.concat(mason_rest, " "))
  end
end)
