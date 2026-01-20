local M = {}

---@class HiExtmark : vim.api.keyset.set_extmark
---@field col? number -- NEW!
---@field row? number -- NEW!

---@param query_range Range4? 0-based, end-exclusive
function M.get_ts_highlights(source, lang, parse_range, query_range)
  parse_range = parse_range == nil and true or parse_range
  query_range = query_range
  local is_range4 = function(r)
    return r[1] and r[2] and r[3] and r[4]
  end
  if query_range and not is_range4(query_range) then
    error("`query_range` must be Range4|nil")
  end
  local parser, err ---@type vim.treesitter.LanguageTree?, string?
  if type(source) == "number" then
    parser, err = vim.treesitter.get_parser(source, lang, { error = false })
  end
  if type(source) == "string" then
    parser, err = vim.treesitter.get_string_parser(source, lang, { error = false })
  end
  if not parser then
    error(err or "Unable to get a parser")
  end
  local ret = {}
  local prior_vals = {}
  local vim_range = function(r)
    return vim.range(r[1], r[2], r[3], r[4])
  end
  local intersect = function(r1, r2)
    local inter = vim_range(r1):intersect(vim_range(r2))
    if not inter then
      return nil
    end
    return { inter.start.row, inter.start.col, inter.end_.row, inter.end_.col }
  end
  parser:parse(parse_range)
  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end
    local root_node = tstree:root()
    local root_range = { root_node:range() }
    local tsquery_range = query_range or root_range
    if not intersect(root_range, tsquery_range) then
      return
    end
    local query = vim.treesitter.query.get(tree:lang(), "highlights")
    if not query then
      return
    end
    for id, node, metadata in
      query:iter_captures(
        root_node,
        source,
        tsquery_range[1],
        tsquery_range[3],
        { start_col = tsquery_range[2], end_col = tsquery_range[4] }
      )
    do
      local capture = query.captures[id]
      if capture ~= nil and capture ~= "spell" then
        local node_text = vim.treesitter.get_node_text(node, source, metadata[id])
        local text = vim.split(node_text, "\n")
        local range = { node:range() }
        local inter = intersect(range, tsquery_range)
        if not inter then
          return
        end
        -- NOTE: row 1-based inclusive, col 0-based exclusive
        local row_start, row_end = inter[1] + 1, inter[4] == 0 and inter[3] or inter[3] + 1
        for row = row_start, row_end do
          local first, last = row == row_start, row == row_end
          local col = first and inter[2] or 0
          local line = text[row - row_start - 1] or ""
          local end_col = last and inter[4] or #line
          -- HACK: +1 `priority` for repeated columns
          local prior = tonumber(metadata.priority) or 100
          local prior_id = vim.inspect({ row, col })
          prior = prior_vals[prior_id] and prior_vals[prior_id] + 1 or prior
          prior_vals[prior_id] = prior
          --
          ret[row] = ret[row] or {}
          table.insert(ret[row], {
            row = row,
            end_row = row,
            col = col,
            end_col = end_col,
            priority = prior,
            conceal = metadata.conceal,
            hl_group = "@" .. capture .. "." .. lang,
          } --[[@as HiExtmark]])
        end
      end
    end
  end)
  local hls_flat = function(hls_tbl)
    local keys = vim.tbl_keys(hls_tbl)
    table.sort(keys)
    -- stylua: ignore
    return vim.tbl_map(function(key) return hls_tbl[key] end, keys)
  end
  -- NOTE: Return highlights grouped by line
  ---@cast ret HiExtmark[][]
  ret = hls_flat(ret)
  return ret
end

function M.get_lang(ft)
  local lang = vim.treesitter.language.get_lang(ft or "")
  if not lang then
    return nil
  end
  if not vim.treesitter.language.add(lang) then
    return nil
  end
  if not vim.api.nvim_get_runtime_file("queries/" .. lang .. "/highlights.scm", false) then
    return nil
  end
  return lang
end

function M.get_text_patched_highlights(text, ft)
  text = type(text) == "table" and table.concat(text, "\n") or text
  local lang = M.get_lang(ft)
  if not lang then
    return nil
  end
  -- HACK: Complete keywords in order to get highlights
  if lang == "lua" then
    local prepend = { ["end"] = "do", ["until"] = "repeat" }
    local append = { ["do"] = "end", ["then"] = "end", ["repeat"] = "until" }
    local lines = vim.split(text, "\n")
    local first, last = lines[1], lines[#lines]
    local from, to = 0, #lines
    for _, word in ipairs(vim.split(first, "%s+")) do
      local add = prepend[word]
      if add then
        table.insert(lines, 1, add)
        from, to = from + 1, to + 1
      end
    end
    for _, word in ipairs(vim.split(last, "%s+")) do
      local add = append[word]
      if add then
        table.insert(lines, add)
      end
    end
    local patched_text = table.concat(lines, "\n")
    return M.get_ts_highlights(patched_text, lang, true, { from, 0, to, 0 })
  end
  return M.get_ts_highlights(text, lang)
end

function M.get_buf_highlights(buf, with_extmarks, ln_range)
  if not vim.api.nvim_buf_is_valid(buf) then
    error(string.format("Invalid buffer: %s", buf))
  end
  ln_range = vim.tbl_extend("keep", ln_range, { -- 0-based exclusive
    [1] = 0,
    [2] = vim.api.nvim_buf_line_count(buf),
  })
  local lang = M.get_lang(vim.bo[buf].ft)
  if not lang then
    return {}
  end
  local range4 = { ln_range[1], 0, ln_range[2], 0 }
  local hls = M.get_ts_highlights(buf, lang, range4, range4) or {}
  if with_extmarks then
    local start_pos, end_pos = { ln_range[1], 0 }, { ln_range[2] - 1, -1 }
    local extm_list = vim.api.nvim_buf_get_extmarks(buf, -1, start_pos, end_pos, { details = true })
    for _, extm in ipairs(extm_list) do
      local row = extm[2] + 1
      local i = ln_range[1] - extm[2] + 1
      local e = extm[4]
      hls[i] = hls[i] or {}
      if e then
        e.sign_name = nil
        e.sign_text = nil
        e.ns_id = nil
        e.end_row = nil
        e.row = row ---@diagnostic disable-line: inject-field
        e.col = extm[3] ---@diagnostic disable-line: inject-field
        if e.virt_text_pos and not vim.tbl_contains({ "eol", "overlay", "right_align", "inline" }, e.virt_text_pos) then
          e.virt_text = nil
          e.virt_text_pos = nil
        end
        table.insert(hls[i], e)
      end
    end
  end
  return hls
end

function M.norm_hl(hl, row, col_offset)
  -- hl = vim.deepcopy(hl, true)
  row, col_offset = row or hl.row, col_offset or 0
  local col = math.max(0, col_offset + hl.col)
  hl.end_row = (hl.end_row and hl.row) and (row + hl.end_row - hl.row) or hl.end_row
  hl.end_col = (hl.end_col and hl.col) and (col + hl.end_col - hl.col) or hl.end_col
  hl.row = nil
  hl.col = nil
  return row, col, hl
end

return M
