local M = {}

vim.F.if_nil(vim.g.root_markers, {})
vim.F.if_nil(vim.g.root_ignore, {})

function M.setup()
  vim.g.cwd_glob = vim.fn.getcwd()
  vim.g.cwd_auto = vim.fn.getcwd()

  vim.api.nvim_create_autocmd("DirChangedPre", {
    group = vim.api.nvim_create_augroup("find_root", { clear = true }),
    callback = function(e)
      if e.match == "global" then
        vim.g.cwd_glob = e.file
      end
      if e.match == "auto" then
        vim.g.cwd_auto = e.file
      end
    end,
  })
end

local path_contain = function(path, ignore_list)
  return vim.iter(ignore_list):any(function(ignore)
    return vim.fs.normalize(path) == vim.fs.normalize(ignore)
  end)
end

function M.find_root(source)
  source = source or vim.g.cwd_glob or vim.fn.getcwd()
  local root = vim.fs.root(source, vim.g.root_markers or {})
  if not root or path_contain(root, vim.g.root_ignore or {}) then
    return nil
  end
  return root
end

return M
