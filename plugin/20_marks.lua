vim.g.virt_marks = vim.F.if_nil(vim.g.virt_marks, true)

local pack = require("util.pack")

-- Virtual marks

pack.later(function()
  local mark_ns = vim.api.nvim_create_namespace("mark_virtual")
  local marks_group = vim.api.nvim_create_augroup("mark_virtual", { clear = true })

  local get_marks = function(buf, filter)
    buf = buf or 0
    buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
    local file = vim.api.nvim_buf_get_name(buf)
    filter = filter or function(m)
      return m.mark:match("'%a")
    end
    -- stylua: ignore start
    local buffer_marks = vim.iter(vim.fn.getmarklist(buf))
      :map(function(m) m.type = "buffer"; return m end)
      :totable()
    local global_marks = vim.iter(vim.fn.getmarklist())
      :filter(function(m) return vim.fn.fnamemodify(m.file, ":p") == file end)
      :map(function(m) m.type = "global"; return m end)
      :totable()
    return vim.iter({ buffer_marks, global_marks }):flatten(1):filter(filter):totable()
  end

  local clear_marks = function(buf)
    vim.api.nvim_buf_clear_namespace(buf, mark_ns, 0, -1)
  end

  local draw_marks = function(buf)
    clear_marks(buf)
    local buf_marks = get_marks(buf)
    local lnum_marks = {}
    for _, m in ipairs(buf_marks) do
      local _, lnum = unpack(m.pos)
      lnum = lnum - 1
      lnum_marks[lnum] = lnum_marks[lnum] or {}
      table.insert(lnum_marks[lnum], m)
    end
    local get_indent = function(lnum)
      local line = table.remove(vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false))
      line = line or ""
      return string.match(line, "^%s+") or ""
    end
    local line_count = vim.api.nvim_buf_line_count(buf)
    for lnum, marks in pairs(lnum_marks) do
      if lnum < line_count then
        local indent = get_indent(lnum)
        local virt_lines = {}
        for _, m in ipairs(marks) do
          table.insert(virt_lines, { { string.format("%s %s", indent, m.mark), "Comment" } })
        end
        vim.api.nvim_buf_set_extmark(buf, mark_ns, lnum, 0, {
          virt_lines = virt_lines,
          virt_lines_above = true,
          strict = false,
        })
      end
    end
    return buf_marks
  end

  local apply_marks = function(buf, enabled)
    vim.g.virt_marks = true
    if enabled ~= nil then
      vim.b[buf].virt_marks = enabled
    end
    if vim.b[buf].virt_marks then
      draw_marks(buf)
    else
      clear_marks(buf)
    end
  end

  local toggle_marks = function(buf)
    buf = buf or 0
    apply_marks(buf, not vim.b[buf].virt_marks)
  end

  local toggle_marks_all = function()
    local next_val = not vim.b.virt_marks
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      apply_marks(buf, next_val)
    end
  end

  -- stylua: ignore
  vim.keymap.set("n", "<Leader>m", function() toggle_marks() end, { desc = "Toggle marks (buf)" })
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>M", function() toggle_marks_all() end, { desc = "Toggle marks" })

  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
    desc = "Show named vim marks as virtual lines",
    group = marks_group,
    callback = function(e)
      local buf = e.buf
      if not vim.api.nvim_buf_is_loaded(buf) then
        return
      end
      if not vim.g.virt_marks then
        return
      end
      if vim.b[buf].virt_marks == nil then
        vim.b[buf].virt_marks = vim.g.virt_marks
      end
      apply_marks(buf)
    end,
  })
end)
