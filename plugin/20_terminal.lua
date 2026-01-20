local pack = require("util.pack")

pack.later(function()
  vim.api.nvim_create_autocmd("TermOpen", {
    desc = "Set options for the terminal window",
    group = vim.api.nvim_create_augroup("term_open", { clear = true }),
    callback = function()
      vim.wo.number = false
      vim.wo.relativenumber = false
    end,
  })

  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

  vim.cmd.cnoreabbrev("Lz", "Lazygit")
  vim.api.nvim_create_user_command("Lazygit", function()
    vim.cmd.tabnew()
    vim.cmd.terminal("lazygit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = function(e)
        vim.cmd.bwipeout({ args = { e.buf }, bang = true })
      end,
    })
    pcall(vim.cmd.file, "term:lazygit")
    vim.cmd.startinsert()
  end, {})
end)

-- Count terminal

pack.later(function()
  _G.Terminal = {
    store = {},
    openinsert = true,
  }

  function Terminal.close(id, unload)
    local term = Terminal.store[id]
    if not term then
      return nil
    end
    local count = nil
    if vim.api.nvim_win_is_valid(term.win) then
      local buf = vim.api.nvim_win_get_buf(term.win)
      count = vim.b[buf].term_count
      _G.Terminal.openinsert = vim.fn.mode() == "t"
      vim.api.nvim_win_close(term.win, unload)
      term.win = -1
    end
    if unload then
      for _, buf in ipairs(term.buflist) do
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      Terminal.store[id] = nil
    end
    return count
  end

  function Terminal.open(id, count, win_config)
    count = count or 1
    win_config = win_config or {}
    Terminal.store[id] = Terminal.store[id] or {
      win = -1,
      buflist = {},
    }
    local term = Terminal.store[id]
    local mods = { mods = { split = "botright" } }
    local new = function(buf, win_conf)
      buf = buf or -1
      win_conf = win_conf or {}
      local is_buf = vim.api.nvim_buf_is_valid(buf)
      if is_buf then
        vim.cmd.split(mods)
      else
        vim.cmd.terminal(mods)
        buf = vim.api.nvim_get_current_buf()
      end
      local win = vim.api.nvim_get_current_win()
      term.win = win
      vim.api.nvim_win_set_config(win, win_conf)
      if is_buf then
        vim.wo[win].winfixbuf = false
        vim.api.nvim_win_set_buf(win, buf)
      end
      vim.wo[win].winfixbuf = true
      term.buflist[count] = buf
      vim.b[buf].term_count = count
      if _G.Terminal.openinsert then
        vim.api.nvim_win_call(term.win, vim.cmd.startinsert)
      end
    end
    if vim.api.nvim_win_is_valid(term.win) then
      local buf = term.buflist[count] or -1
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_win_set_config(0, win_config)
        vim.wo[term.win].winfixbuf = false
        vim.api.nvim_win_set_buf(term.win, buf)
        vim.wo[term.win].winfixbuf = true
      else
        local win_state = vim.api.nvim_win_get_config(term.win)
        vim.api.nvim_win_close(term.win, false)
        new(nil, win_state)
      end
    else
      local buf = term.buflist[count] or -1
      new(buf, win_config)
    end
    return term.win
  end

  local last_count = 1 ---@type integer?
  local win = -1
  local win_config = { height = 15 } ---@type vim.api.keyset.win_config
  local open_term = function(count)
    win = Terminal.open("default", count, win_config)
    vim.wo[win].winbar = "Terminal " .. count
  end
  vim.keymap.set({ "v", "n", "t" }, "<M-`>", function()
    if vim.api.nvim_win_is_valid(win) then
      local conf = vim.api.nvim_win_get_config(win)
      local is_vert = vim.list_contains({ "above", "below" }, conf.split)
      win_config.height = is_vert and conf.height or 15
      win_config.split = "below"
      if vim.v.count == 0 then
        last_count = Terminal.close("default", false)
      else
        open_term(vim.v.count1)
      end
    else
      open_term(vim.v.count == 0 and last_count or vim.v.count1)
    end
  end, { desc = "Terminal" })
end)
