vim.g.session_center = false
vim.g.session_ft_ignore = {
  "gitcommit",
  "gitrebase",
}

vim.g.root_ignore = { "~", "/" }
vim.g.root_markers = {
  ".git",
  "Makefile",
  "package.json",
}

vim.g.ts_install = {
  "bash",
  "c",
  "css",
  "diff",
  "go",
  "html",
  "javascript",
  "json",
  "lua",
  "python",
  "toml",
  "tsx",
  "typescript",
  "yaml",
  "zig",
}

vim.g.mason_install = {
  "delve",
  "deno",
  "gopls",
  "lua-language-server",
  "prettier",
  "shfmt",
  "stylua",
}

vim.g.lsp_enable = {
  "gopls",
  "lua_ls",
}

vim.g.format_on_save = true

local buf_name = function(buf)
  return vim.api.nvim_buf_get_name(buf or 0)
end

---@type table<string, fun(line1:integer,line2:integer):FormatBufOpts|FormatBufOpts[]>
local formatters = {
  stylua = function()
    return { cmd = { "stylua", "--indent-type=Spaces", "--indent-width=2", "--stdin-filepath", buf_name(), "-" } }
  end,
  prettier = function()
    return { cmd = { "prettier", "--stdin-filepath", buf_name() } }
  end,
  shfmt = function()
    return { cmd = { "shfmt", "--indent=2", "-" } }
  end,
}

vim.g.formatconf = {
  ["javascript"] = formatters["prettier"],
  ["javascriptreact"] = formatters["prettier"],
  ["json"] = formatters["prettier"],
  ["jsonc"] = formatters["prettier"],
  ["lua"] = formatters["stylua"],
  ["markdown"] = formatters["prettier"],
  ["scss"] = formatters["prettier"],
  ["sh"] = formatters["shfmt"],
  ["typescript"] = formatters["prettier"],
  ["typescriptreact"] = formatters["prettier"],
  ["yaml"] = formatters["prettier"],
}
