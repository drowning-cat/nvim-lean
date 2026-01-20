local pack = require("util.pack")

pack.later(function()
  local MiniFiles = require("mini.files")

  MiniFiles.setup({
    windows = {
      preview = false,
      width_preview = 100,
    },
  })

  local open_buf_file = function(buf)
    buf = buf or 0
    MiniFiles.open(vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) or nil, false)
  end
  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>F", function() MiniFiles.open() end, { desc = "Open files" })
  vim.keymap.set("n", "<Leader>.F", function() open_buf_file() end, { desc = "Open files (current buf)" })
  vim.keymap.set("n", "<Leader>@F", function() MiniFiles.open(vim.fn.getcwd()) end, { desc = "Open files (cwd)" })
  vim.keymap.set("n", "<Leader>~F", function() MiniFiles.open("~") end, { desc = "Open files (system home)" })
  -- stylua: ignore end

  local files_au = vim.api.nvim_create_augroup("minifiles", { clear = true })

  local get_path = function(buf)
    local path = vim.api.nvim_buf_get_name(buf):match("^minifiles://%d+/(.*)$")
    local stat = vim.uv.fs_stat(path)
    return path, stat
  end

  local function get_preview_win()
    if not MiniFiles.config.windows.preview then
      return
    end
    local state = MiniFiles.get_explorer_state()
    if not state then
      return
    end
    local rightmost_win = state.windows[#state.windows].win_id
    if rightmost_win == vim.api.nvim_get_current_win() then
      return
    end
    return rightmost_win
  end

  local preview_win_call = function(callback)
    local win = get_preview_win()
    if win then
      vim.api.nvim_win_call(win, callback)
    end
  end

  -- Buf keymaps

  local show_hidden = true

  local toggle_hidden = function()
    show_hidden = not show_hidden
    local filter_show = function()
      return true
    end
    local filter_hide = function(fs_entry)
      return not vim.startswith(fs_entry.name, ".")
    end
    MiniFiles.refresh({
      content = { filter = show_hidden and filter_show or filter_hide },
    })
  end

  local toggle_preview = function()
    local is_preview = MiniFiles.config.windows.preview
    local is_preview_next = not is_preview
    MiniFiles.config.windows.preview = is_preview_next
    MiniFiles.trim_right()
    MiniFiles.refresh({ windows = { preview = is_preview_next } })
    if is_preview then
      local branch = MiniFiles.get_explorer_state().branch
      table.remove(branch)
      MiniFiles.set_branch(branch)
    end
  end

  local search_grep = function()
    local MiniPick = require("mini.pick")
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local parent = vim.fn.fnamemodify(entry.path, ":h")
    MiniPick.registry.grep({ pattern = "." }, { source = { cwd = parent } })
  end
  local search_files = function()
    local MiniPick = require("mini.pick")
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local parent = vim.fn.fnamemodify(entry.path, ":h")
    MiniPick.registry.files(nil, { source = { cwd = parent } })
  end

  local norm_in_preview = function(keys)
    preview_win_call(function()
      local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
      vim.cmd.norm({ key, bang = true })
    end)
  end
  local jump_edges = function()
    preview_win_call(function()
      local last = vim.fn.line(".") == vim.fn.line("$")
      vim.cmd.norm({ last and "gg" or "G", bang = true })
    end)
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    desc = "Set `mini.files` buffer keymaps",
    group = files_au,
    callback = function(e)
      local buf_map = function(mode, lhs, rhs, opts)
        opts = vim.tbl_extend("keep", opts or {}, { buffer = e.data.buf_id })
        vim.keymap.set(mode, lhs, rhs, opts)
      end
      -- stylua: ignore start
      buf_map("n", "g.", function() toggle_hidden() end, { desc = "Toggle hiddent" })
      buf_map("n", "<M-p>", function() toggle_preview() end, { desc = "Toggle preview" })
      buf_map("n", "<Leader>sg", function() search_grep() end, { desc = "Search grep" })
      buf_map("n", "<Leader>sf", function() search_files() end, { desc = "Search files" })
      buf_map("n", "<C-b>", function() norm_in_preview("<C-u>") end, { desc = "Scroll preview backwards" })
      buf_map("n", "<C-f>", function() norm_in_preview("<C-d>") end, { desc = "Scroll preview upwards" })
      buf_map("n", "<C-g>", function() jump_edges() end, { desc = "Jump edges" })
    end,
  })

  -- Win options

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowUpdate",
    desc = "Set `mini.files` 'number' option",
    group = files_au,
    callback = function(e)
      local win = e.data.win_id
      local buf = e.data.buf_id
      local is_preview = win == get_preview_win()
      local _, stat = get_path(buf)
      local is_dir = stat and stat.type == "directory"
      vim.wo[win].number = not (is_preview and is_dir)
      vim.wo[win].relativenumber = not is_preview
      vim.wo[win].cursorline = not is_preview
    end,
  })

  -- Bookmarks

  local set_bookmark = function(id, path, opts)
    MiniFiles.set_bookmark(id, function()
      path = vim.is_callable(path) and path() or path
      if type(path) ~= "string" then
        return path
      end
      path = vim.fs.abspath(path)
      local stat = vim.uv.fs_stat(path)
      if not stat then
        return path
      end
      if stat.type == "directory" then
        return path
      else
        vim.schedule(function()
          if vim.bo.ft == "minifiles" then
            local buf = 0
            local win = 0
            for line = 1, vim.api.nvim_buf_line_count(buf) do
              local entry = MiniFiles.get_fs_entry(buf, line)
              if entry.path == path then
                vim.api.nvim_win_set_cursor(win, { line, 0 })
              end
            end
          end
        end)
        return vim.fs.dirname(path)
      end
    end, opts)
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesExplorerOpen",
    desc = "Define `mini.files` bookmarks (supports file bookmarks)",
    group = files_au,
    callback = function()
      local target_win = MiniFiles.get_explorer_state().target_window
      local target_buf = vim.api.nvim_win_get_buf(target_win)
      set_bookmark("%", vim.api.nvim_buf_get_name(target_buf), { desc = "Target file" })
      set_bookmark("@", vim.fn.getcwd, { desc = "Cwd" })
      set_bookmark("n", vim.fn.stdpath("config") .. "/init.lua", { desc = "Config" })
      set_bookmark("p", vim.fn.stdpath("data") .. "/site/pack/core/opt", { desc = "Plugins" })
    end,
  })

  -- Resize preview

  local refresh_preview = function()
    local width_focus = MiniFiles.config.windows.width_focus
    local width_preview = MiniFiles.config.windows.width_preview
    local preview_width = math.min(vim.o.columns - width_focus - 4, width_preview)
    MiniFiles.refresh({ windows = { width_preview = preview_width } })
  end

  local resize_autocmd = function(event, opts)
    vim.api.nvim_create_autocmd(
      event,
      vim.tbl_extend("keep", opts, { desc = "Resize `mini.files` preview to be always visible", group = files_au })
    )
  end

  resize_autocmd("VimResized", { callback = refresh_preview })
  resize_autocmd("User", { pattern = "MiniFilesWindowOpen", callback = vim.schedule_wrap(refresh_preview) })

  -- Custom preview: extend lines

  local validate_file = function(path)
    local fd, _, err = vim.uv.fs_open(path, "r", 1)
    if not fd then
      return err, nil
    end
    local is_binary = vim.uv.fs_read(fd, 1024):find("\0") ~= nil
    vim.uv.fs_close(fd)
    return false, is_binary
  end

  local files_preview_ns = vim.api.nvim_create_namespace("minifiles")

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferUpdate",
    desc = "Extend `mini.files` preview lines; adjust preview error display",
    callback = function(args)
      local buf = args.data.buf_id
      local path, stat = get_path(buf)
      if not stat or stat.type == "directory" then
        return
      end
      local extm_id = 1
      local error = function(msg)
        local hl = "Text"
        vim.treesitter.stop(buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
        vim.api.nvim_buf_set_extmark(buf, files_preview_ns, 0, 0, {
          id = extm_id,
          virt_text_pos = "overlay",
          virt_text = { { msg, hl } },
        })
      end
      local warn = function(msg)
        local hl = "WarningMsg"
        vim.api.nvim_buf_set_extmark(buf, files_preview_ns, 0, 0, {
          id = extm_id,
          virt_text_pos = "right_align",
          virt_text = { { msg, hl } },
        })
      end
      local no_access, is_binary = validate_file(path)
      local format_msg = function(msg)
        msg = " " .. msg .. string.rep(" ", MiniFiles.config.windows.width_preview)
        return string.gsub(msg, " ", "-")
      end
      if no_access then
        error(format_msg("No access"))
        return
      end
      if is_binary then
        error(format_msg("Non text file"))
        return
      end
      if stat.size > 512 * 1024 then
        warn("Large file detected (>512KB)")
        return
      end
      local read_ok, read_lines = pcall(vim.fn.readfile, path, "")
      if read_ok then
        local lines = vim.split(table.concat(read_lines, "\n"), "\n")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      end
    end,
  })
end)
