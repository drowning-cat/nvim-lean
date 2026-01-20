vim.keymap.set({ "i", "c" }, "<C-S-h>", "<Left>")
vim.keymap.set({ "i", "c" }, "<C-S-j>", "<Down>")
vim.keymap.set({ "i", "c" }, "<C-S-k>", "<Up>")
vim.keymap.set({ "i", "c" }, "<C-S-l>", "<Right>")

-- vim.keymap.set("x", "p", "P")
-- vim.keymap.set("x", "P", "p")

vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<Enter>")

vim.keymap.set("o", "C", "gc", { remap = true, desc = "Comment textobject" })

vim.keymap.set("n", "gA", "<Cmd>tabnew|b#<Enter>", { desc = "Add tab" })
vim.keymap.set("n", "gC", "<Cmd>tabclose<Enter>", { desc = "Close tab" })

vim.keymap.set("n", "<C-w>Q", "<Cmd>qall<Enter>", { desc = "Quit" })

-- Restart

local tmp_session = "Restart.vim"

function _G.after_restart(orig_session)
  vim.g.session_load = false -- NOTE: See `MiniSession`
  vim.cmd.source(tmp_session)
  vim.fs.rm(tmp_session, { force = true })
  vim.v.this_session = orig_session
end

vim.keymap.set("n", "<Leader>R", function()
  local this_session = vim.v.this_session
  vim.cmd.write({ mods = { silent = true, emsg_silent = true } })
  vim.cmd.mksession({ tmp_session, bang = true })
  vim.cmd.restart(string.format("lua _G.after_restart('%s')", this_session))
end, { desc = "Restart" })

-- Copy to clipboard

vim.keymap.set("n", "gy", function()
  local copy = vim.fn.getreg('"')
  if copy == "" then
    return
  end
  vim.fn.setreg("+", copy)
  local msg = ""
  local _, ln = string.gsub(copy, "\n", "")
  if ln > 0 then
    msg = string.format('%s %s yanked into "+', ln, ln > 1 and "lines" or "line")
  else
    local ch = vim.fn.strdisplaywidth(copy)
    msg = string.format('%s %s yanked into "+', ch, ch > 1 and "chars" or "char")
  end
  vim.api.nvim_echo({ { msg } }, false, {})
end, { desc = "Yank last into clipboard" })

-- Quickfix toggle

local qf_height = { l = 10, c = 10 }
local toggle_list = function(nr)
  local mods = { split = "botright" }
  local type, win
  if nr then
    type, win = "l", vim.fn.getloclist(nr, { winid = true }).winid
  else
    type, win = "c", vim.fn.getqflist({ winid = true }).winid
  end
  if win > 0 then
    qf_height[type] = vim.api.nvim_win_get_height(win)
    vim.cmd({ cmd = type .. "close", mods = mods })
  else
    vim.cmd({ cmd = type .. "open" })
    vim.api.nvim_win_set_height(0, qf_height[type])
  end
end

-- stylua: ignore
vim.keymap.set("n", "<Leader>l", function() toggle_list() end, { desc = "Toggle qf" })
-- stylua: ignore
vim.keymap.set("n", "<Leader>L", function() toggle_list(0) end, { desc = "Toggle loc" })
