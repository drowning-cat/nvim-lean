local pack = require("util.pack")

pack.later(function()
  local MiniGit = require("mini.git")

  MiniGit.setup()

  vim.cmd.cnoreabbrev("G", "Git")
  vim.cmd.cnoreabbrev("Gc", "Git commit")
  vim.cmd.cnoreabbrev("Gcm", "Git commit --message")
  vim.cmd.cnoreabbrev("Gca", "Git commit --amend")
  vim.cmd.cnoreabbrev("Gcan", "Git commit --amend --no-edit")

  -- Git blame

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniGitCommandSplit",
    desc = "Enhance `Git blame`: colorize buffer and set width for vertical split",
    group = vim.api.nvim_create_augroup("mini_gitblame", { clear = true }),
    callback = function(e)
      if e.data.git_subcommand ~= "blame" then
        return
      end
      local win_src = e.data.win_source
      local buf = e.buf
      local win = e.data.win_stdout
      vim.bo[buf].modifiable = false
      vim.wo[win].wrap = false
      vim.wo[win].cursorline = true
      vim.fn.winrestview({ topline = vim.fn.line("w0", win_src) })
      vim.api.nvim_win_set_cursor(0, { vim.fn.line(".", win_src), 0 })
      vim.wo[win].scrollbind, vim.wo[win_src].scrollbind = true, true
      vim.wo[win].cursorbind, vim.wo[win_src].cursorbind = true, true
      if string.match(e.data.cmd_input.mods, "vertical") then
        local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
        local width = vim.iter(lines):fold(-1, function(acc, ln)
          local stat = string.match(ln, "^[%w%p]+ %b()")
          return math.max(acc, vim.fn.strwidth(stat))
        end)
        width = width + vim.fn.getwininfo(win)[1].textoff
        vim.api.nvim_win_set_width(win, width)
      end
      local leftmost = [[^.\{-}\zs]]
      -- stylua: ignore start
      --[[ ^hash  ]] vim.fn.matchadd("Tag", [[^^\w\+]])
      --[[ hash   ]] vim.fn.matchadd("Identifier", [[^\w\+]])
      --[[ author ]] vim.fn.matchadd("String", leftmost .. [[(\zs.\{-} \ze\d\{4}-]])
      --[[ date   ]] vim.fn.matchadd("Comment", leftmost .. [[[0-9-]\{10} [0-9:]\{8} [+-]\d\+]])
    end,
  })

  -- Checkout

  local conflict_ns = vim.api.nvim_create_namespace("git_conflict")
  local conflict_au = vim.api.nvim_create_augroup("git_conflict", { clear = false })

  -- get_buf_conflicts(buf) -> { { {1,5}, {3,5}, {5,7} }, ... }
  --                               ours   base?  theirs
  -- 1: <<<<<<< HEAD
  -- 2: local a = "main"
  -- 3: ||||||| parent of xxxxxxx (xxx)
  -- 4: local a = "base"
  -- 5: =======
  -- 6: local a = "feature"
  -- 7: >>>>>>> xxxxxxx (xxx)
  --
  local function find_conflicts(buf)
    buf = buf or 0
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local ours, base, theirs = {}, {}, {}
    local conflicts = {}
    local on_end_mark = function()
      local full = function(val)
        return val[1] and val[2]
      end
      if full(ours) and full(theirs) then
        base = full(base) and base or nil
        table.insert(conflicts, { ours, base, theirs })
        ours, base, theirs = {}, {}, {}
      end
    end
    -- stylua: ignore
    for ln, line in ipairs(lines) do
      if vim.startswith(line, "<<<<<<<") then ours[1] = ln end
      if vim.startswith(line, "|||||||") then base[1] = ln end
      if vim.startswith(line, "=======") then ours[2], base[2], theirs[1] = ln, ln, ln end
      if vim.startswith(line, ">>>>>>>") then theirs[2] = ln; on_end_mark() end
    end
    return conflicts
  end

  local conflict_state = {}
  local function toggle_conflicts(buf)
    buf = buf or 0
    if not vim.api.nvim_buf_is_valid(buf) then
      vim.notify(string.format("Invalid buffer: %d", buf), vim.log.levels.ERROR)
      return
    end
    conflict_state[buf] = not conflict_state[buf]
    if not conflict_state[buf] then
      vim.api.nvim_clear_autocmds({ group = conflict_au, buffer = buf })
      vim.api.nvim_buf_clear_namespace(buf, conflict_ns, 0, -1)
      vim.b[buf].minigit_conflicts = nil
    else
      local update = function() ---@diagnostic disable-line: redefined-local
        local conflicts = find_conflicts(buf)
        vim.b[buf].minigit_conflicts = conflicts
        vim.api.nvim_buf_clear_namespace(buf, conflict_ns, 0, -1)
        local hi = function(from, to, hl)
          vim.api.nvim_buf_set_extmark(buf, conflict_ns, from - 1, 0, {
            end_row = to,
            hl_group = hl,
            hl_eol = true,
          })
        end
        for _, conflict in ipairs(conflicts) do
          local ours, base, theirs = unpack(conflict)
          hi(ours[1], ours[2] - 1, "DiffText")
          hi(theirs[1] + 1, theirs[2], "DiffAdd")
          if base then
            hi(base[1], base[2] - 1, "DiffDelete")
          end
        end
      end
      update()
      vim.api.nvim_clear_autocmds({ group = conflict_au, buffer = buf })
      vim.api.nvim_create_autocmd("ModeChanged", { pattern = "i:*", group = conflict_au, callback = update })
      vim.api.nvim_create_autocmd("TextChanged", { group = conflict_au, buffer = buf, callback = update })
    end
  end

  local conflict_acts = {}
  do
    local get_conflict = function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      for _, conflict in ipairs(vim.b.minigit_conflicts or {}) do
        local ours, _, theirs = unpack(conflict)
        if lnum >= ours[1] and lnum <= theirs[2] then
          return conflict
        end
      end
    end
    local replace_conflict = function(conflict, lines)
      local ours, _, theirs = unpack(conflict)
      vim.api.nvim_buf_set_lines(0, ours[1] - 1, theirs[2], true, lines)
      vim.api.nvim_win_set_cursor(0, { ours[1], 0 })
    end
    local get_lines = function(from, to)
      return vim.api.nvim_buf_get_lines(0, from - 1, to - 1, true)
    end
    local search = function(line, pattern, ...)
      line = type(line) == "number" and line or vim.fn.line(line)
      local saved_pos = vim.fn.getpos(".")
      vim.fn.cursor(line, 0)
      if vim.fn.search(pattern, ...) == 0 or vim.fn.line(".") == saved_pos[2] then
        vim.fn.cursor(saved_pos[2], saved_pos[3])
      end
    end
    --
    conflict_acts.ours = function()
      local conflict = get_conflict()
      if conflict then
        local ours, base, _ = unpack(conflict)
        local repl = get_lines(ours[1] + 1, base[1] or ours[2])
        replace_conflict(conflict, repl)
      end
    end
    conflict_acts.theirs = function()
      local conflict = get_conflict()
      if conflict then
        local _, _, theirs = unpack(conflict)
        local repl = get_lines(theirs[1] + 1, theirs[2])
        replace_conflict(conflict, repl)
      end
    end
    conflict_acts.both = function()
      local conflict = get_conflict()
      if conflict then
        local ours, base, theirs = unpack(conflict)
        local repl = {}
        vim.list_extend(repl, get_lines(ours[1] + 1, base[1] or ours[2]))
        vim.list_extend(repl, get_lines(theirs[1] + 1, theirs[2]))
        replace_conflict(conflict, repl)
      end
    end
    conflict_acts.none = function()
      local conflict = get_conflict()
      if conflict then
        replace_conflict(conflict, {})
      end
    end
    conflict_acts.forward = function()
      for _ = 1, vim.v.count1 do
        search(".", "^<<<<<<< ")
      end
    end
    conflict_acts.backward = function()
      for _ = 1, vim.v.count1 do
        search(".", "^<<<<<<< ", "b")
      end
    end
    conflict_acts.last = function()
      search("$", "^<<<<<<< ", "bW")
    end
    conflict_acts.first = function()
      search(1, "^<<<<<<< ", "cW")
    end
  end

  local function minigit_is_merge(buf)
    buf = buf or 0
    local git_summary = vim.b[buf].minigit_summary or {}
    local in_progress = git_summary.in_progress
    return in_progress and (in_progress:find("merge") or in_progress:find("rebase"))
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniGitUpdated",
    group = conflict_au,
    callback = function(e)
      local buf = e.buf
      if minigit_is_merge(buf) then
        if not vim.b[buf].minigit_conflicts then
          toggle_conflicts(buf)
          vim.keymap.set("n", "co", conflict_acts.ours, { buffer = buf, desc = "Checkout ours" })
          vim.keymap.set("n", "ct", conflict_acts.theirs, { buffer = buf, desc = "Checkout theirs" })
          vim.keymap.set("n", "cb", conflict_acts.both, { buffer = buf, desc = "Checkout both" })
          vim.keymap.set("n", "c0", conflict_acts.none, { buffer = buf, desc = "Checkout none" })
          vim.keymap.set("n", "]x", conflict_acts.forward, { buffer = buf, desc = "Conflict forward" })
          vim.keymap.set("n", "[x", conflict_acts.backward, { buffer = buf, desc = "Conflict backward" })
          vim.keymap.set("n", "]X", conflict_acts.last, { buffer = buf, desc = "Conflict last" })
          vim.keymap.set("n", "[X", conflict_acts.first, { buffer = buf, desc = "Conflict first" })
        end
      else
        if vim.b[buf].minigit_conflicts then
          toggle_conflicts(buf)
          vim.keymap.del("n", "co", { buffer = buf })
          vim.keymap.del("n", "ct", { buffer = buf })
          vim.keymap.del("n", "cb", { buffer = buf })
          vim.keymap.del("n", "c0", { buffer = buf })
          vim.keymap.del("n", "]x", { buffer = buf })
          vim.keymap.del("n", "[x", { buffer = buf })
          vim.keymap.del("n", "]X", { buffer = buf })
          vim.keymap.del("n", "[X", { buffer = buf })
        end
      end
    end,
  })
end)
