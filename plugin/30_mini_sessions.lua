vim.g.session_ft_ignore = vim.F.if_nil(vim.g.session_ft_ignore, {})

local pack = require("util.pack")

pack.now(function()
  local session_load = vim.g.session_load or true
  local session_center = vim.g.session_center

  local util_root = require("util.root")
  local find_root = util_root.find_root

  local MiniSessions = require("mini.sessions")

  local root_session = function()
    local root = find_root()
    return root and (string.gsub(root, "/", "%%")) or nil
  end

  MiniSessions.setup({
    directory = vim.fn.stdpath("state") .. "/sessions",
    autoread = false,
    autowrite = true,
    hooks = {
      pre = {
        write = function()
          vim.fn.mkdir(MiniSessions.config.directory, "p")
        end,
      },
      post = {
        read = function()
          if session_center then
            vim.cmd('normal! zz"')
          end
        end,
      },
    },
  })

  vim.cmd.cnoreabbrev("Lo", "Load")
  vim.cmd.cnoreabbrev("Sa", "Save")
  vim.cmd.cnoreabbrev("La", "Last")

  local ncall = function(level, ...)
    local ok, err = pcall(...)
    if not ok then
      vim.notify(err, vim.log.levels[level])
    end
  end

  local minisession_run = function(action, get_session)
    local session = get_session()
    if not session then
      vim.notify("(mini.sessions) No session found", vim.log.levels.WARN)
    else
      ncall("WARN", MiniSessions[action], session)
    end
  end

  vim.api.nvim_create_user_command("Load", function()
    minisession_run("read", root_session)
  end, {})
  vim.api.nvim_create_user_command("Save", function()
    minisession_run("write", root_session)
  end, {})
  vim.api.nvim_create_user_command("Last", function()
    minisession_run("read", MiniSessions.get_latest)
  end, {})

  local load_au = vim.api.nvim_create_augroup("session_load", { clear = true })
  local save_au = vim.api.nvim_create_augroup("session_save", { clear = true })

  -- Load

  if vim.fn.argc() == 0 then
    vim.api.nvim_create_autocmd("VimEnter", {
      desc = "Load session on `vim` with no args",
      group = load_au,
      nested = true,
      callback = function()
        -- NOTE: See `Restart`
        if session_load and vim.bo.buftype == "" then
          vim.cmd("silent Load")
        end
      end,
    })
  end

  -- Save

  vim.api.nvim_create_autocmd("VimLeave", {
    desc = "Save session on `VimLeave`",
    group = save_au,
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].ft
        if vim.list_contains(vim.g.session_ft_ignore, ft) then
          vim.api.nvim_win_close(win, true)
        end
      end
      vim.cmd("silent Save")
    end,
  })
end)
