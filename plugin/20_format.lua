vim.g.format_on_save = vim.F.if_nil(vim.g.format_on_save, true)
vim.g.formatconf = vim.F.if_nil(vim.g.formatconf, {})

local pack = require("util.pack")

pack.later(function()
  ---@class FormatBufOpts
  ---@field cmd string[]
  ---@field stdin? [integer,integer]
  ---@field range? [integer,integer]
  ---@field transform? fun(out: string): string[]
  ---@field diff? "any"|"none"|"overlap"|"contain"
  ---@field diff_algorithm? "myers"|"minimal"|"patience"|"histogram"
  ---@field timeout? integer
  ---@field silent? boolean
  ---@field after_exit? fun(out: vim.SystemCompleted)

  ---@param buf? integer
  ---@param opts? FormatBufOpts
  local function format_buf(buf, opts)
    buf = buf or 0
    opts = vim.tbl_extend("keep", opts or {}, {
      cmd = nil,
      stdin = {}, -- [line1, line2)
      range = {}, -- [line1, line2)
      transform = function(out)
        return vim.split(out, "\n")
      end,
      diff = "overlap",
      diff_algorithm = "histogram",
      timeout = 2500,
      silent = false,
      after_exit = function() end,
    })
    local cmd = opts.cmd
    if not vim.islist(cmd) then
      vim.notify("Invalid 'cmd': expected a list of strings", vim.log.levels.ERROR)
      return
    end
    local stdin1 = opts.stdin[1] or 1
    local stdin2 = opts.stdin[2] or vim.api.nvim_buf_line_count(buf) + 1
    local range1 = opts.range[1] or stdin1
    local range2 = opts.range[2] or stdin2
    local mode = vim.fn.mode()
    if vim.tbl_isempty(opts.range) and mode:match("[vV]") then
      local v1 = vim.api.nvim_win_get_cursor(0)[1]
      local v2 = vim.fn.getpos("v")[2]
      range1 = math.min(v1, v2)
      range2 = math.max(v1, v2) + 1
    end
    local lines = vim.api.nvim_buf_get_lines(buf, stdin1 - 1, stdin2 - 1, true)
    local file = vim.api.nvim_buf_get_name(buf)
    ---@param out vim.SystemCompleted
    local on_exit = vim.schedule_wrap(function(out)
      if out.code == 0 then
        local fmt = assert(out.stdout, "No stdout")
        local fmt_lines = opts.transform(fmt)
        if opts.diff == "none" then
          vim.api.nvim_buf_set_lines(buf, stdin1 - 1, stdin2 - 1, true, fmt_lines)
          return
        end
        local lines_str = table.concat(lines, "\n") .. "\n"
        local diff_opts = { result_type = "indices", algorithm = opts.diff_algorithm }
        local diff = vim.text.diff(lines_str, fmt, diff_opts)
        if not diff then
          return
        end
        for i = #diff, 1, -1 do
          local d = diff[i]
          local a = { d[1], d[1] + d[2] }
          local b = { d[3], d[3] + d[4] }
          local a_buf = { a[1] + stdin1 - 1, a[2] + stdin1 - 1 }
          local set_hunk = function()
            local repl = b[1] == b[2] and {} or vim.list_slice(fmt_lines, b[1], b[2] - 1)
            local offs = a[1] == a[2] and 0 or -1
            vim.api.nvim_buf_set_lines(buf, a_buf[1] + offs, a_buf[2] + offs, false, repl)
          end
          if opts.diff == "any" then
            set_hunk()
          end
          if opts.diff == "contain" then
            if range1 <= a_buf[1] and range2 >= a_buf[2] then
              set_hunk()
            end
          end
          if opts.diff == "overlap" then
            if range1 <= a_buf[2] and a_buf[1] <= range2 then
              set_hunk()
            end
          end
        end
      else
        if not opts.silent then
          vim.notify(string.format("-%s- %s", cmd[1], out.stderr), vim.log.levels.ERROR)
        end
      end
      opts.after_exit(out)
    end)
    local sysopts = { ---@type vim.SystemOpts
      stdin = lines,
      text = true,
      cwd = vim.fs.dirname(file),
      timeout = opts.timeout,
    }
    return vim.system(cmd, sysopts, on_exit)
  end

  ---@class FormatOpts
  ---@field range? [integer,integer]
  ---@field async? boolean
  ---@field or_lsp? boolean
  ---@field silent? boolean

  ---@param local_opts? FormatOpts
  local format = function(local_opts)
    local_opts = vim.tbl_extend("keep", local_opts or {}, {
      range = {},
      async = false,
      or_lsp = true,
      silent = false,
    })
    local range = local_opts.range
    local formatconf = vim.g.formatconf or {}
    local conf = formatconf[vim.bo.ft]
    if not vim.is_callable(conf) then
      if local_opts.or_lsp then
        local lsp_range = nil
        if not vim.tbl_isempty(range) then
          lsp_range = { ["start"] = { range[1], 0 }, ["end"] = { range[2] - 1, -1 } }
        end
        vim.lsp.buf.format({ range = lsp_range, async = local_opts.async })
      end
      return false
    end
    local line1 = range[1] or 1
    local line2 = range[2] or vim.api.nvim_buf_line_count(0) + 1
    local mode = vim.fn.mode()
    if vim.tbl_isempty(range) and mode:match("[vV]") then
      local v1 = vim.api.nvim_win_get_cursor(0)[1]
      local v2 = vim.fn.getpos("v")[2]
      line1 = math.min(v1, v2)
      line2 = math.max(v1, v2) + 1
    end
    ---@return vim.SystemCompleted
    local format_co = function(buf, opts)
      opts = vim.tbl_extend("keep", opts or {}, {
        range = { line1, line2 },
        silent = local_opts.silent,
      })
      if local_opts.async then
        local co = coroutine.running()
        local after_exit = opts.after_exit
        opts.after_exit = function(out)
          if type(after_exit) == "function" then
            after_exit(out)
          end
          coroutine.resume(co, out)
        end
        format_buf(buf, opts)
        return coroutine.yield()
      else
        return format_buf(buf, opts):wait()
      end
    end
    local co = coroutine.create(function()
      local fmt_opts = conf(line1, line2)
      fmt_opts = vim.islist(fmt_opts) and fmt_opts or { fmt_opts }
      for _, opts in ipairs(fmt_opts) do
        local out = format_co(0, opts)
        if out.code ~= 0 then
          break
        end
      end
    end)
    coroutine.resume(co)
    return co
  end

  _G.Formatexpr = function()
    format({ range = { vim.v.lnum, vim.v.lnum + vim.v.count } })
  end

  vim.o.formatexpr = "v:lua.Formatexpr()"
  vim.keymap.set("n", "gqag", function()
    format()
  end)
  vim.keymap.set("n", "gqga", function()
    format()
  end)

  vim.api.nvim_create_user_command("Format", function()
    format()
  end, {})

  vim.cmd.cnoreabbrev("A", "AutoformatToggle")
  vim.api.nvim_create_user_command("AutoformatToggle", function()
    vim.g.format_on_save = not vim.g.format_on_save
    vim.notify(string.format("Autoformat: %s", vim.g.format_on_save))
  end, {})

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("format_on_save", { clear = true }),
    callback = function()
      local if_unset = false
      local is_enabled = vim.F.if_nil(vim.b.format_on_save, vim.g.format_on_save, if_unset)
      if is_enabled then
        format({ async = true, silent = true })
      end
    end,
  })
end)
