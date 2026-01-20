local M = {}

setmetatable(M, { __index = vim.pack })

function M.now(callback)
  callback()
end

function M.later(callback)
  vim.schedule(callback)
end

return M
