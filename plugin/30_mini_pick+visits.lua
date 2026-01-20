local pack = require("util.pack")

local util_hi = require("util.highlight")
local get_buf_highlights = util_hi.get_buf_highlights
local get_text_patched_highlights = util_hi.get_text_patched_highlights
local norm_hl = util_hi.norm_hl

pack.now(function()
  local MiniExtra = require("mini.extra")

  local MiniVisits = require("mini.visits")
  MiniVisits.setup()

  local MiniPick = require("mini.pick")

  vim.api.nvim_set_hl(0, "MiniPickMatchRanges", {
    bold = true,
    underdotted = true,
  })

  local minipick_hl_ns = vim.api.nvim_create_namespace("minipick_hl")

  local pick_colorize = function(buf, data, get_hls)
    vim.api.nvim_buf_clear_namespace(buf, minipick_hl_ns, 0, -1)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    for i = 1, #data do
      local item, line = data[i], lines[i]
      local start, hls = get_hls(item, line)
      if start and hls and not vim.tbl_isempty(hls) then
        local row_start, col_offset = i - 1, start - 1
        -- NOTE: To prevent cache changes
        hls = vim.deepcopy(hls, true)
        for j, row_hls in ipairs(hls) do
          local row = row_start + j - 1
          for _, hl in ipairs(row_hls) do
            vim.api.nvim_buf_set_extmark(buf, minipick_hl_ns, norm_hl(hl, row, col_offset))
          end
        end
      end
    end
  end

  local minipick_cache = {}

  local pick_cache = function(id, func)
    if not vim.list_contains({ "string", "number" }, type(id)) then
      error("Cache 'id' must be 'string' or 'number'")
    end
    if minipick_cache[id] == nil then
      minipick_cache[id] = { func() }
    end
    return unpack(minipick_cache[id])
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniPickStop",
    callback = function()
      minipick_cache = {}
    end,
  })

  -- Overrides (+colors)

  MiniPick.registry.buf_lines = function(local_opts, opts)
    local find_pattern = local_opts.scope == "all" and "^.-│.-│()" or "^.-│()"
    local show = function(buf, data, query)
      MiniPick.default_show(buf, data, query, opts)
      pick_colorize(buf, data, function(item, line)
        local item_buf, row = item.bufnr, item.lnum
        local id = vim.inspect({ item_buf, row })
        return pick_cache(id, function()
          local start = string.match(line, find_pattern)
          local hls = get_buf_highlights(item_buf, true, { row - 1, row })
          return start, hls
        end)
      end)
    end
    opts = vim.tbl_deep_extend("keep", opts or {}, { source = { show = show } })
    return MiniExtra.pickers.buf_lines(local_opts, opts)
  end

  MiniPick.registry.git_hunks = function(local_opts, opts)
    local choose_marked = function(items)
      if vim.tbl_isempty(items) then
        items = { MiniPick.get_picker_matches().current }
      end
      local patches = {}
      for _, item in ipairs(items) do
        vim.list_extend(patches, item.header)
        vim.list_extend(patches, item.hunk)
      end
      local cmd = { "git", "apply", "--cached" }
      if local_opts.scope == "staged" then
        table.insert(cmd, "--reverse")
      end
      vim.system(cmd, { stdin = patches })
    end
    local show = function(buf, data, query)
      MiniPick.default_show(buf, data, query, opts)
      -- NOTE: Replace `hunk header` with the first changed line [+-]
      --       See https://github.com/nvim-mini/mini.nvim/discussions/2190
      local lines = vim.api.nvim_buf_get_lines(buf, 0, #data, true)
      for i = 1, #data do
        local item, line = data[i], lines[i]
        local first_changed = vim.iter(item.hunk):find(function(l)
          return string.match(l, "^[+-]")
        end)
        if first_changed then
          local row_0 = i - 1
          local col_0 = string.match(line, "^.-│.-│()") - 1
          line = string.gsub(first_changed, "^([+-])%s*", "%1 ")
          vim.api.nvim_buf_set_text(buf, row_0, col_0, row_0, -1, { line })
        end
      end
      -- Color lines
      pick_colorize(buf, data, function(item, line)
        local id, start, code = string.match(line, "^(.-│.-│)[+-]()(.*)")
        return pick_cache(id, function()
          local file = item.path
          local ft = vim.filetype.match({ filename = file, contents = { code } })
          return start, get_text_patched_highlights(code, ft)
        end)
      end)
    end
    opts = vim.tbl_deep_extend("keep", opts or {}, { source = { choose_marked = choose_marked, show = show } })
    return MiniExtra.pickers.git_hunks(local_opts, opts)
  end

  local grep_show = function(buf, data, query, opts)
    opts = opts or {}
    MiniPick.default_show(buf, data, query, opts)
    pick_colorize(buf, data, function(item, line)
      local file, row, col, code = unpack(vim.split(item, "%z"))
      local id = vim.inspect({ file, row, col })
      return pick_cache(id, function()
        local start = string.match(line, "^.-│.-│.-│()")
        local ft = vim.filetype.match({ filename = file, contents = { code } })
        return start, get_text_patched_highlights(code, ft)
      end)
    end)
  end

  MiniPick.registry.grep = function(local_opts, opts)
    local show = grep_show
    opts = vim.tbl_deep_extend("keep", opts or {}, { source = { show = show } })
    return MiniPick.builtin.grep(local_opts, opts)
  end

  MiniPick.registry.grep_live = function(local_opts, opts)
    local_opts = vim.tbl_extend("keep", local_opts or {}, { globs = {} })
    opts = vim.tbl_extend("keep", opts or {}, { source = {} })
    local cwd = vim.fs.abspath(opts.source.cwd or vim.fn.getcwd())
    local set_items_opts = { do_match = false, querytick = MiniPick.get_querytick() }
    local rg_cmd = function(pattern, globs)
      local cmd =
        { "rg", "--column", "--line-number", "--no-heading", "--field-match-separator", "\\x00", "--color=never" }
      for _, g in ipairs(globs) do
        vim.list_extend(cmd, { "--glob", g })
      end
      local case = vim.o.ignorecase and (vim.o.smartcase and "smart-case" or "ignore-case") or "case-sensitive"
      vim.list_extend(cmd, { "--" .. case })
      vim.list_extend(cmd, { "--", pattern })
      return cmd
    end
    local parse_globs = function(query_str)
      local escape = function(str)
        return str:gsub("\\ ", "\1")
      end
      local unescape = function(str)
        return str:gsub("\1", "\\ ")
      end
      local after_split = vim.split(escape(query_str), "%s+", { trimempty = true })
      return vim.tbl_map(unescape, after_split)
    end
    local glob_mode = false
    local glob_query = {}
    local pattern_query = {}
    local query_globs = {}
    local globs = {}
    local process
    local match = function(_, _, query)
      pcall(vim.loop.process_kill, process)
      if MiniPick.get_querytick() == set_items_opts.querytick then
        return
      end
      if glob_mode then
        glob_query = query
        query_globs = parse_globs(table.concat(query))
        globs = {}
        vim.list_extend(globs, local_opts.globs)
        vim.list_extend(globs, query_globs)
      else
        pattern_query = query
      end
      if vim.tbl_isempty(pattern_query) and vim.tbl_isempty(query_globs) then
        return MiniPick.set_picker_items({}, set_items_opts)
      end
      set_items_opts.querytick = MiniPick.get_querytick()
      local cmd = rg_cmd(table.concat(pattern_query), globs)
      process = MiniPick.set_picker_items_from_cli(cmd, { set_items_opts = set_items_opts, spawn_opts = { cwd = cwd } })
    end
    local toggle_glob = function()
      glob_mode = not glob_mode
      if glob_mode then
        MiniPick.set_picker_opts({ source = { name = "Grep live (rg*)" } })
        MiniPick.set_picker_query(glob_query)
      else
        local suffix = vim.tbl_isempty(globs) and "" or " | " .. table.concat(globs, ", ")
        local source_name = string.format("Grep live (rg%s)", suffix)
        MiniPick.set_picker_opts({ source = { name = source_name } })
        MiniPick.set_picker_query(pattern_query)
      end
    end
    local show = grep_show
    return MiniPick.start(vim.tbl_deep_extend("force", opts or {}, {
      source = {
        name = "Grep live (rg)",
        items = {},
        match = match,
        show = show,
      },
      mappings = {
        toggle_glob = { char = "<C-o>", func = toggle_glob },
      },
    }))
  end

  MiniPick.registry.hipatterns = function(local_opts, opts)
    local show = function(buf, data, query)
      MiniPick.default_show(buf, data, query, opts)
      pick_colorize(buf, data, function(item, line)
        local item_buf, row, col = item.bufnr, item.lnum, item.col
        local id = vim.inspect({ item_buf, row, col })
        return pick_cache(id, function()
          local start = string.match(line, "^.-│.-│.-│.-│()")
          local hls = get_buf_highlights(item_buf, false, { row - 1, row })
          return start, hls
        end)
      end)
      -- NOTE: After colorize
      for i = 1, #data do
        local item = data[i]
        local highlighter, hl_group = item.highlighter, item.hl_group
        local row, end_col = i - 1, #highlighter
        local extm = { hl_group = hl_group, end_row = row, end_col = end_col }
        vim.api.nvim_buf_set_extmark(buf, minipick_hl_ns, row, 0, extm)
      end
    end
    opts = vim.tbl_deep_extend("keep", opts or {}, { source = { show = show } })
    return MiniExtra.pickers.hipatterns(local_opts, opts)
  end

  MiniPick.registry.history = function(local_opts, opts)
    local show = function(buf, data, query)
      MiniPick.default_show(buf, data, query, opts)
      pick_colorize(buf, data, function(item, line)
        local id = item
        return pick_cache(id, function()
          local start = string.match(line, "^: ()")
          if start then
            local code = string.sub(line, start)
            local ft = "vim"
            return start, get_text_patched_highlights(code, ft)
          end
        end)
      end)
    end
    opts = vim.tbl_deep_extend("keep", opts or {}, { source = { show = show } })
    return MiniExtra.pickers.history(local_opts, opts)
  end

  MiniPick.registry.lsp = function(local_opts, opts)
    local find_pattern = local_opts.scope == "document_symbol" and "^.-[.-]()(.*)" or "^.-│.-│.-│()(.*)"
    local show = function(buf, data, query)
      MiniPick.default_show(buf, data, query, opts)
      pick_colorize(buf, data, function(item, line)
        local file, row, col = item.path, item.lnum, item.col
        local id = vim.inspect({ file, row, col })
        return pick_cache(id, function()
          local start, code = string.match(line, find_pattern)
          local ft = vim.filetype.match({ filename = file, contents = { code } })
          return start, get_text_patched_highlights(code, ft)
        end)
      end)
    end
    opts = vim.tbl_deep_extend("keep", opts or {}, { source = { show = show } })
    return MiniExtra.pickers.lsp(local_opts, opts)
  end

  -- Overrides (other)

  MiniPick.registry.colorschemes = function(local_opts, opts)
    local aug = vim.api.nvim_create_augroup("pick_colors", { clear = true })
    local fake_buf = vim.api.nvim_create_buf(false, true)
    local cl = vim.g.colors_name or "default"
    local bg = vim.o.background or "dark"
    local preview = function(colors)
      local matches = MiniPick.get_picker_matches()
      if matches then
        local item = colors or matches.current
        local func = MiniPick.get_picker_opts().source.preview
        pcall(func, fake_buf, item)
        vim.o.background = bg
      end
    end
    local match_current = function()
      local matches = MiniPick.get_picker_matches()
      local current = vim.iter(matches.all_inds):find(function(i)
        return cl == matches.all[i]
      end)
      if current then
        MiniPick.set_picker_match_inds({ current }, "current")
      end
    end
    local on_move = function()
      vim.schedule(preview)
    end
    vim.api.nvim_create_autocmd("User", { pattern = "MiniPickStart", group = aug, callback = match_current })
    vim.api.nvim_create_autocmd("User", { pattern = "MiniPickMatch", group = aug, callback = on_move })
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniPickStop",
      group = aug,
      once = true,
      callback = function()
        vim.api.nvim_clear_autocmds({ group = aug })
        vim.api.nvim_buf_delete(fake_buf, { unload = true })
      end,
    })
    local remap_move = function(char, keys)
      return {
        char = char,
        func = function()
          vim.api.nvim_input(keys)
          on_move()
        end,
      }
    end
    return MiniExtra.pickers.colorschemes(
      local_opts,
      vim.tbl_deep_extend("keep", opts or {}, {
        source = {
          choose = function(item)
            vim.cmd.colorscheme(item)
            vim.g.COLORS_NAME = vim.g.colors_name
            vim.g.COLORS_BG = vim.o.background
            vim.cmd.wshada()
          end,
        },
        mappings = {
          match_current = {
            char = "<C-0>",
            func = function()
              match_current()
              on_move()
            end,
          },
          change_bg = {
            char = "<C-o>",
            func = function()
              bg = vim.o.background == "dark" and "light" or "dark"
              vim.o.background = bg
            end,
          },
          move_start = "<C-Home>",
          scroll_down = "<PageDown>",
          scroll_up = "<PageUp>",
          move_start_alt = remap_move("<C-g>", "<C-Home>"),
          move_down_alt = remap_move("<C-n>", "<Down>"),
          move_up_alt = remap_move("<C-p>", "<Up>"),
          move_down_2_alt = remap_move("<C-j>", "<Down>"),
          move_up_2_alt = remap_move("<C-k>", "<Up>"),
          scroll_down_alt = remap_move("<C-f>", "<PageDown>"),
          scroll_up_alt = remap_move("<C-b>", "<PageUp>"),
        },
      })
    )
  end

  MiniPick.registry.files = function(_, opts)
    local cli_opts = {
      command = { "fd", "-t=f", "-H", "-I", "-E=.git", "-E=node_modules" },
    }
    local show = function(buf, items, query)
      MiniPick.default_show(buf, items, query, { show_icons = true })
    end
    return MiniPick.builtin.cli(
      cli_opts,
      vim.tbl_deep_extend("keep", opts or {}, {
        source = {
          name = "Files (fd)",
          show = show,
        },
        mappings = {
          open_file = {
            char = "<S-Enter>",
            func = function()
              local current = MiniPick.get_picker_matches().current
              if MiniFiles then
                vim.schedule(function()
                  MiniFiles.open(current, true)
                end)
                return true
              end
            end,
          },
        },
      })
    )
  end

  -- New pickers

  MiniPick.registry.grep_todo = function(local_opts, opts)
    local words = { "FIX", "FIXME", "BUG", "NOTE", "TODO", "FEAT", "WARN", "WARNING", "HACK", "PERF" }
    local pattern = "(" .. table.concat(words, "|") .. ")[ :]"
    local_opts = vim.tbl_extend("keep", local_opts or {}, { pattern = pattern })
    return MiniPick.registry.grep(local_opts, opts)
  end

  -- Setup

  local run_keys = function(keys, rep)
    vim.api.nvim_input(string.rep(keys, rep or 1))
  end

  local pick_move_caret = function(next_caret)
    local caret = MiniPick.get_picker_state().caret
    local query = MiniPick.get_picker_query()
    next_caret = math.max(1, math.min(next_caret, #query + 1))
    local move = next_caret - caret
    run_keys(move >= 0 and "<Right>" or "<Left>", math.abs(move))
  end

  local pick_remap = function(char, keys)
    return {
      char = char,
      func = function()
        run_keys(keys)
      end,
    }
  end

  MiniPick.setup({
    mappings = {
      choose_marked = "<C-Enter>",
      quickfix = {
        char = "<C-q>",
        func = function()
          local all_items = MiniPick.get_picker_items()
          local marked = MiniPick.get_picker_matches().marked
          local choose = vim.tbl_isempty(marked) and all_items or marked
          MiniPick.default_choose_marked(choose, { list_type = "quickfix" })
        end,
      },
      caret_start = {
        char = "<Home>",
        func = function()
          pick_move_caret(1)
        end,
      },
      caret_end = {
        char = "<End>",
        func = function()
          pick_move_caret(math.huge)
        end,
      },
      prev_word = {
        char = "<C-Left>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local regex = vim.regex([=[\([^[:keyword:][:space:]]\+\|\k\+\)\s*$]=])
          local from, _ = regex:match_str(string.sub(query_str, 1, caret - 1))
          pick_move_caret(from and from + 1 or 1)
        end,
      },
      next_word = {
        char = "<C-Right>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local regex = vim.regex([=[^\([^[:keyword:][:space:]]\+\|\k\+\)\s*]=])
          local _, to = regex:match_str(string.sub(query_str, caret))
          pick_move_caret(to and to + caret or math.huge)
        end,
      },
      prev_before_space = {
        char = "<C-S-Left>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local search_str = string.sub(query_str, 1, caret - 1)
          local word_start = string.find(search_str, "%S+%s*$")
          pick_move_caret(word_start or 1)
        end,
      },
      next_before_space = {
        char = "<C-S-Right>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local word_end = string.find(query_str, "%f[%s]", caret + 1)
          pick_move_caret(word_end or #query_str + 1)
        end,
      },
      move_down_alt = pick_remap("<C-j>", "<C-n>"),
      move_up_alt = pick_remap("<C-k>", "<C-p>"),
      caret_prev_alt = pick_remap("<C-a>", "<C-Left>"),
      caret_next_alt = pick_remap("<C-e>", "<C-Right>"),
    },
  })

  -- stylua: ignore start
  local buf_name = function(buf) return vim.api.nvim_buf_get_name(buf or 0) end
  -- mini.pick
  vim.keymap.set("n", "<Leader>sb", function() MiniPick.registry.buffers() end, { desc = "Search buffers" })
  vim.keymap.set("n", "<Leader>sf", function() MiniPick.registry.files() end, { desc = "Search files" })
  vim.keymap.set("n", "<Leader>sg", function() MiniPick.registry.grep_live() end, { desc = "Search grep" })
  vim.keymap.set("n", "<Leader>sh", function() MiniPick.registry.help() end, { desc = "Search help" })
  vim.keymap.set("n", "<Leader>sr", function() MiniPick.registry.resume() end, { desc = "Search resume" })
  -- mini.extra
  vim.keymap.set("n", "<Leader>sl", function() MiniPick.registry.buf_lines({ scope = "current" }) end, { desc = "Search lines (buf)" })
  vim.keymap.set("n", "<Leader>sL", function() MiniPick.registry.buf_lines({ scope = "all" }) end, { desc = "Search lines (all)" })
  vim.keymap.set("n", "<Leader>sa", function() MiniPick.registry.git_hunks({ path = buf_name(), scope = "staged" }) end, { desc = "Search added hunks (buf)" })
  vim.keymap.set("n", "<Leader>sA", function() MiniPick.registry.git_hunks({ scope = "staged" }) end, { desc = "Search added hunks (all)" })
  vim.keymap.set("n", "<Leader>sm", function() MiniPick.registry.git_hunks() end, { desc = "Search modified hunks (all)" })
  vim.keymap.set("n", "<Leader>sM", function() MiniPick.registry.git_hunks({ path = buf_name() }) end, { desc = "Search modified hunks (buf)" })
  vim.keymap.set("n", "<Leader>sc", function() MiniPick.registry.git_commits({ path = buf_name() }) end, { desc = "Search commits (buf)" })
  vim.keymap.set("n", "<Leader>sC", function() MiniPick.registry.git_commits() end, { desc = "Search commits (all)" })
  vim.keymap.set("n", "<Leader>sd", function() MiniPick.registry.diagnostic({ scope = "current" }) end, { desc = "Search diagnostics (buf)" })
  vim.keymap.set("n", "<Leader>sD", function() MiniPick.registry.diagnostic({ scope = "all" }) end, { desc = "Search diagnostics (workspace)" })
  vim.keymap.set("n", "<Leader>sR", function() MiniPick.registry.lsp({ scope = "references" }) end, { desc = "Search LSP refs" })
  vim.keymap.set("n", "<Leader>ss", function() MiniPick.registry.lsp({ scope = "document_symbol" }) end, { desc = "Search LSP symbols (doc)" })
  vim.keymap.set("n", "<Leader>sS", function() MiniPick.registry.lsp({ scope = "workspace_symbol_live" }) end, { desc = "Search LSP symbols (workspace)" })
  vim.keymap.set("n", "<Leader>sH", function() MiniPick.registry.hl_groups() end, { desc = "Search highlights" })
  vim.keymap.set("n", "<Leader>s/", function() MiniPick.registry.history({ scope = "/" }) end, { desc = "Search '/' history" })
  vim.keymap.set("n", "<Leader>s:", function() MiniPick.registry.history({ scope = ":" }) end, { desc = "Search cmd history" })
  vim.keymap.set("n", "<Leader>s'", function() MiniPick.registry.marks() end, { desc = "Search marks" })
  vim.keymap.set("n", "<Leader>s`", function() MiniPick.registry.registers() end, { desc = "Search register" })
  vim.keymap.set("n", "<Leader>so", function() MiniPick.registry.colorschemes() end, { desc = "Search colorschemes" })
  -- mini.visits
  vim.keymap.set("n", "<Leader>v", function() MiniVisits.add_label("favorites") end, { desc = 'Add "core" label' })
  vim.keymap.set("n", "<Leader>V", function() MiniVisits.remove_label("favorites") end, { desc = 'Remove "core" label' })
  vim.keymap.set("n", "<Leader>sv", function() MiniPick.registry.visit_paths({ filter = "favorites" }) end, { desc = "Search visits (cwd)" })
  vim.keymap.set("n", "<Leader>sV", function() MiniPick.registry.visit_paths({ cwd = "", filter = "favorites" }) end, { desc = "Search visits (all)" })
end)
