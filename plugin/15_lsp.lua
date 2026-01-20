vim.g.lsp_enable = vim.F.if_nil(vim.g.lsp_enable, {})
vim.g.doc_highlight = vim.F.if_nil(vim.g.doc_highlight, false)

local pack = require("util.pack")

pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

pack.now(function()
  vim.lsp.enable(vim.g.lsp_enable or {})
  vim.diagnostic.config({ virtual_text = true })

  vim.keymap.set("n", "gK", function()
    local state = not vim.diagnostic.config().virtual_text
    vim.diagnostic.config({ virtual_text = state, underline = state })
  end, { desc = "Toggle diagnostic" })

  vim.keymap.set("n", "gI", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, { desc = "Toggle inlay" })

  local dochi_au = vim.api.nvim_create_augroup("doc_highlight", { clear = true })

  vim.api.nvim_set_hl(0, "LspReferenceText", { link = "Underlined" })

  vim.keymap.set("n", "gR", function()
    vim.lsp.buf.clear_references()
    vim.g.doc_highlight = not vim.g.doc_highlight
  end, { desc = "Toggle document highlight" })

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Setup document highlight",
    callback = function(e)
      local client = assert(vim.lsp.get_client_by_id(e.data.client_id))
      local buf = e.buf
      if not client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        return
      end
      local cleanup = false
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = dochi_au,
        buffer = buf,
        callback = function()
          if vim.g.doc_highlight then
            vim.lsp.buf.document_highlight()
            cleanup = true
          end
        end,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = dochi_au,
        buffer = buf,
        callback = function()
          if cleanup then
            vim.lsp.buf.clear_references()
            cleanup = false
          end
        end,
      })
    end,
  })
end)

-- Undim current diagnostic

pack.later(function()
  local undim_au = vim.api.nvim_create_augroup("undim_diagnostic", { clear = false })
  local function toggle_undim(buf, client_id)
    buf = buf or 0
    local client = assert(vim.lsp.get_client_by_id(client_id), "Unable to get LSP client by provided 'client_id'")
    local tagSupport = client.capabilities.textDocument.diagnostic.tagSupport.valueSet
    if not vim.list_contains(tagSupport, 1) then
      return false
    end
    local name = string.format("nvim.nvim.lsp.%s.%d.diagnostic.underline", client.name, client.id)
    local ns = vim.api.nvim_create_namespace(name)
    local iter_unnecessary = function()
      local diagnostics = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.HINT })
      return vim.iter(diagnostics):filter(function(diagn)
        return diagn._tags and diagn._tags.unnecessary
      end)
    end
    local set_hl = function(diagn)
      vim.api.nvim_buf_set_extmark(buf, ns, diagn.lnum, diagn.col, {
        hl_group = "DiagnosticUnnecessary",
        end_line = diagn.end_lnum,
        end_col = diagn.end_col,
        strict = false,
      })
    end
    local del_hl = function(diagn)
      local from = { diagn.lnum, diagn.col }
      local to = { diagn.end_lnum, diagn.end_col }
      local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns, from, to, {})
      for _, extm in ipairs(extmarks) do
        vim.api.nvim_buf_del_extmark(buf, ns, extm[1])
      end
    end
    local state = vim.b[buf].undim_diagnostics or {}
    state[client.id] = not state[client.id]
    vim.b[buf].undim_diagnostics = state
    if not state[client.id] then
      vim.api.nvim_clear_autocmds({ buffer = buf, group = undim_au })
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      for diagn in iter_unnecessary() do
        set_hl(diagn)
      end
    else
      local update = function()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        --
        local cursor = vim.api.nvim_win_get_cursor(0)
        local lnum, col = cursor[1] - 1, cursor[2]
        local in_range = function(diagn)
          return (lnum >= diagn.lnum and lnum <= diagn.end_lnum) --
            and (diagn.lnum ~= diagn.end_lnum or col < diagn.end_col)
        end
        for diagn in iter_unnecessary() do
          if in_range(diagn) then
            del_hl(diagn)
          else
            set_hl(diagn)
          end
        end
      end
      vim.api.nvim_create_autocmd("ModeChanged", {
        buffer = buf,
        group = undim_au,
        callback = function()
          local mode = vim.fn.mode()
          if mode == "n" then
            update()
          elseif mode == "c" then
          else
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
          end
        end,
      })
      vim.api.nvim_create_autocmd({ "CursorHold", "DiagnosticChanged" }, {
        buffer = buf,
        group = undim_au,
        callback = function()
          if vim.fn.mode() == "n" then
            update()
          end
        end,
      })
    end
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Undim unused code in normal mode",
    group = vim.api.nvim_create_augroup("undim_diagnostic", { clear = true }),
    callback = function(e)
      local buf, client_id = e.buf, e.data.client_id
      local state = vim.b[buf].undim_unnecessary or {}
      if not state[client_id] then
        toggle_undim(e.buf, e.data.client_id)
      end
    end,
  })
end)

-- Lsp progress

pack.later(function()
  local au = vim.api.nvim_create_augroup("lsp_progress", { clear = true })
  local ns = vim.api.nvim_create_namespace("lsp_progress")
  local timer = assert(vim.uv.new_timer())
  local buf = -1
  local win = -1
  local minmax = function(val, min, max)
    return math.floor(math.max(min, math.min(val, max)))
  end
  local text_overflow = function(line, max_width)
    if #line <= max_width then
      return line
    end
    local ell = "..."
    local cut = max_width - vim.fn.strwidth(ell)
    if cut <= 0 then
      return ell .. line
    end
    return line:sub(1, cut) .. ell
  end
  local lsp_notify = function(lines, hl, keep_ms)
    hl = hl or "Comment"
    keep_ms = keep_ms or nil
    if vim.tbl_isempty(lines) then
      return
    end
    local vpad, hpad = 0, 0
    local min_width, min_height = 1, 1
    local max_width, max_height = vim.o.columns / 3, vim.o.lines - 5
    local text_width = vim.iter(lines):fold(1, function(max, val)
      return math.max(max, #val)
    end)
    local width = math.floor(minmax(text_width, min_width, max_width))
    local height = math.floor(minmax(#lines, min_height, max_height))
    local win_config = { ---@type vim.api.keyset.win_config
      relative = "editor",
      anchor = "SE",
      row = vim.o.lines - 2,
      col = vim.o.columns,
      width = width + hpad * 2,
      height = height + vpad * 2,
      zindex = 100,
      style = "minimal",
      border = "single",
      focusable = false,
      noautocmd = true,
    }
    if not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].ft = "lsp_progress"
    end
    if not vim.api.nvim_win_is_valid(win) then
      win = vim.api.nvim_open_win(buf, false, win_config)
      vim.wo[win].eventignorewin = "WinClosed"
      vim.wo[win].winhighlight = "Search:None,CurSearch:None"
    else
      vim.api.nvim_win_set_config(win, win_config)
    end
    local buf_lines = lines
    local cut_edge = vim.api.nvim_win_get_width(win) - hpad * 2
    for i, line in ipairs(buf_lines) do
      buf_lines[i] = text_overflow(line, cut_edge)
    end
    local padded = {}
    local hp = string.rep(" ", hpad)
    local vline = string.rep(" ", width + hpad * 2)
    local vp = vim.fn["repeat"]({ vline }, vpad)
    vim.list_extend(padded, vp)
    for _, line in ipairs(lines) do
      table.insert(padded, hp .. line .. hp)
    end
    vim.list_extend(padded, vp)
    buf_lines = padded
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
    vim.hl.range(buf, ns, hl, { 0, 0 }, { #buf_lines, -1 })
    if keep_ms and keep_ms > 1 then
      timer:start(keep_ms, 0, function()
        timer:stop()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end)
      end)
    end
  end
  vim.api.nvim_create_autocmd("LspProgress", {
    desc = "Show LSP progress status",
    group = au,
    callback = function()
      local msg = string.gsub(vim.lsp.status(), "^%s*%d+%%: ", "")
      local msg_lines = vim.split(msg, ", ")
      -- e.data.params.value.kind == "end"
      lsp_notify(msg_lines, "LspProgress", 1500)
    end,
  })
end)
