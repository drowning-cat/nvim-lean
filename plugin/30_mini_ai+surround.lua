local pack = require("util.pack")

-- Ai

pack.later(function()
  local MiniAi = require("mini.ai")

  MiniAi.setup({
    mappings = {
      around_next = "an",
      inside_next = "in",
      around_last = "",
      inside_last = "",
      goto_left = "g[",
      goto_right = "g]",
    },
    custom_textobjects = {
      C = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
      F = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
      I = MiniAi.gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
      O = MiniAi.gen_spec.treesitter({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      a = MiniAi.gen_spec.argument({ separator = ",%s*" }),
      e = function(ai_type, id, opts)
        if ai_type == "a" then
          return {
            {
              -- pattern, [^_]pattern_*
              "%f[%a_/\\%-]%l+%d*[_/\\%-]*",
              "%f[%w_/\\%-]%d+[_/\\%-]*",
              "%f[%u_/\\%-]%u%f[%A]%d*[_/\\%-]*",
              "%f[%u_/\\%-]%u%l+%d*[_/\\%-]*",
              "%f[%u_/\\%-]%u%u+%d*[_/\\%-]*",
              -- __pattern
              "%f[_/\\%-][_/\\%-]+%l+%d*",
              "%f[_/\\%-][_/\\%-]+%d+",
              "%f[_/\\%-][_/\\%-]+%u%f[%A]%d*",
              "%f[_/\\%-][_/\\%-]+%u%l+%d*",
              "%f[_/\\%-][_/\\%-]+%u%u+%d*",
            },
          }
        end
        if ai_type == "i" then
          local reg = MiniAi.find_textobject("a", id, opts)
          if reg then
            local line = vim.fn.getline(reg.from.line)
            local _, s = line:find("^[_/\\%-]*.", reg.from.col)
            local e = line:sub(1, reg.to.col):find(".[_/\\%-]*$")
            return vim.tbl_deep_extend("force", reg, { from = { col = s }, to = { col = e } })
          end
        end
      end,
      g = function()
        local from = { line = 1, col = 1 }
        local to = {
          line = vim.fn.line("$"),
          col = math.max(vim.fn.getline("$"):len(), 1),
        }
        return { from = from, to = to }
      end,
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
    },
  })

  vim.keymap.set("n", ",", function()
    local char = vim.fn.getcharstr()
    local id = string.lower(char)
    local ai_type = string.match(id, "[ea]") and "i" or "a"
    local search_method = char == id and "next" or "prev"
    MiniAi.move_cursor("left", ai_type, id, { search_method = search_method, n_times = vim.v.count1 })
  end)
end)

-- Surround

pack.later(function()
  local MiniSurround = require("mini.surround")

  local surround_sel = function()
    local mark1 = vim.api.nvim_buf_get_mark(0, vim.v.operator == ":" and "<" or "[")
    local mark2 = vim.api.nvim_buf_get_mark(0, vim.v.operator == ":" and ">" or "]")
    local range = { mark1[1], mark1[2], mark2[1], mark2[2] }
    range[4] = math.min(range[4], #vim.fn.getline(range[3]) - 1)
    local text_lines = vim.api.nvim_buf_get_text(0, range[1] - 1, range[2], range[3] - 1, range[4] + 1, {})
    return text_lines, range
  end

  local ts_surround = function(...)
    return {
      input = MiniSurround.gen_spec.input.treesitter(...),
    }
  end

  MiniSurround.setup({
    mappings = {
      find = "",
      find_left = "",
      highlight = "",
      update_n_lines = "",
      suffix_last = "",
      suffix_next = "",
    },
    custom_surroundings = {
      F = ts_surround({ outer = "@function.outer", inner = "@function.inner" }),
      l = nil, -- Reserved for `log`
      L = {
        output = function()
          if not vim.b.minisurround_config.custom_surroundings.l then
            return
          end
          local sel_lines, sel_range = surround_sel()
          local indent_str = string.match(vim.fn.getline(sel_range[1]), "^%s*")
          sel_lines[1] = string.gsub(sel_lines[1], "^%s*", indent_str)
          vim.api.nvim_buf_set_lines(0, sel_range[3], sel_range[3], true, sel_lines)
          vim.api.nvim_win_set_cursor(0, { sel_range[3] + 1, #indent_str })
          vim.cmd.norm("v")
          vim.api.nvim_win_set_cursor(0, { sel_range[3] + #sel_lines, sel_range[4] })
          vim.cmd.norm("sal")
        end,
      },
    },
  })
end)
