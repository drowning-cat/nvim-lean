if vim.fn.has("nvim-0.12") == 0 then
  return vim.notify("Install Neovim 0.12+", vim.log.levels.ERROR)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.number = true
vim.o.relativenumber = true

vim.o.signcolumn = "yes"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabclose = "uselast"

vim.o.confirm = true

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 2
vim.o.softtabstop = 2

vim.o.foldmethod = "indent"
vim.o.foldtext = ""
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldnestmax = 10

vim.o.undofile = true
vim.o.undolevels = 10000

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.list = true
vim.o.listchars = "tab:▷ ,trail:·,nbsp:○"

-- Custom settings

vim.g.session_center = false
vim.g.session_root = {
  ".git",
  "Makefile",
  "package.json",
}

vim.g.ts_install = {
  "bash",
  "c",
  "css",
  "diff",
  "go",
  "html",
  "javascript",
  "json",
  "lua",
  "python",
  "toml",
  "tsx",
  "typescript",
  "yaml",
  "zig",
}

vim.g.mason_install = {
  "delve",
  "deno",
  "gopls",
  "lua-language-server",
  "prettier",
  "shfmt",
  "stylua",
}

vim.g.lsp_enable = {
  "gopls",
  "lua_ls",
}

local buf_name = function(buf)
  return vim.api.nvim_buf_get_name(buf or 0)
end

---@type table<string, fun(line1:integer,line2:integer):FormatOpts|FormatOpts[]>
local formatters = {
  stylua = function()
    return { cmd = { "stylua", "--indent-type=Spaces", "--indent-width=2", "--stdin-filepath", buf_name(), "-" } }
  end,
  prettier = function()
    return { cmd = { "prettier", "--stdin-filepath", buf_name() } }
  end,
  shfmt = function()
    return { cmd = { "shfmt", "-" } }
  end,
}

vim.g.formatconf = {
  ["javascript"] = formatters["prettier"],
  ["javascriptreact"] = formatters["prettier"],
  ["json"] = formatters["prettier"],
  ["jsonc"] = formatters["prettier"],
  ["lua"] = formatters["stylua"],
  ["markdown"] = formatters["prettier"],
  ["scss"] = formatters["prettier"],
  ["sh"] = formatters["shfmt"],
  ["typescript"] = formatters["prettier"],
  ["typescriptreact"] = formatters["prettier"],
  ["yaml"] = formatters["prettier"],
}

-- Core

require("vim._extui").enable({
  msg = {
    target = "cmd",
    timeout = 4000,
  },
})

-- -- Commands

vim.api.nvim_create_user_command("Mkdir", function(o)
  local path = vim.fn.expand(o.args ~= "" and o.args or "%:p:h")
  vim.fn.mkdir(path, "p")
end, { nargs = "?", complete = "dir" })

-- -- Mappings

vim.keymap.set("i", "<C-l>", "<Right>")

vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<Enter>")

vim.keymap.set("n", "<Leader>w", "<Cmd>write<Enter>", { desc = "Save" })
vim.keymap.set("n", "<Leader>q", "<Cmd>quit<Enter>", { desc = "Quit" })
vim.keymap.set("n", "<Leader>Q", "<Cmd>quitall!<Enter>", { desc = "Quit all" })
vim.keymap.set("n", "<Leader>R", "<Cmd>write | restart<Enter>", { desc = "Restart", silent = true })

vim.keymap.set("n", "gA", "<Cmd>tabnew<Enter>", { desc = "Add tab" })
vim.keymap.set("n", "gC", "<Cmd>tabclose<Enter>", { desc = "Close tab" })

vim.keymap.set("o", "C", "gc", { remap = true, desc = "Comment textobject" })

vim.keymap.set("n", "[p", '<Cmd>exe "put! " . v:register<CR>', { desc = "Paste Above" })
vim.keymap.set("n", "]p", '<Cmd>exe "put "  . v:register<CR>', { desc = "Paste Below" })

vim.keymap.set("n", "gy", function()
  local copy = vim.fn.getreg('"')
  if copy == "" then
    return
  end
  local msg = ""
  local _, ln = string.gsub(copy, "\n", "")
  if ln > 0 then
    msg = string.format('%s %s yanked into "+', ln, ln > 1 and "lines" or "line")
  else
    local ch = #copy
    msg = string.format('%s %s yanked into "+', ch, ch > 1 and "chars" or "char")
  end
  vim.fn.setreg("+", copy)
  vim.api.nvim_echo({ { msg } }, false, {})
end, { desc = "Yank last into clipboard" })

local qf_height = { l = 10, c = 10 }
local toggle_list = function(nr)
  local mods = { split = "botright" }
  local type, win
  if nr then
    type, win = "l", vim.fn.getloclist(nr, { winid = true }).winid
  else
    type, win = "c", vim.fn.getqflist({ winid = true }).winid
  end
  if win > 0 then
    qf_height[type] = vim.api.nvim_win_get_height(win)
    vim.cmd({ cmd = type .. "close", mods = mods })
  else
    vim.cmd({ cmd = type .. "open" })
    vim.api.nvim_win_set_height(0, qf_height[type])
  end
end
-- stylua: ignore
vim.keymap.set("n", "<Leader>L", function() toggle_list(0) end, { desc = "Toggle loc" })
-- stylua: ignore
vim.keymap.set("n", "<Leader>l", function() toggle_list() end, { desc = "Toggle qf" })

-- -- Autocmds

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanking text",
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("save_colors", { clear = true }),
  callback = function()
    vim.g.COLORS_NAME = vim.g.colors_name
    vim.g.COLORS_BG = vim.o.background
  end,
})

-- Plugins

vim.api.nvim_create_autocmd("PackChanged", {
  pattern = "blink.cmp",
  desc = "Run `:BlinkCmp build` after pack update",
  group = vim.api.nvim_create_augroup("blink_update", { clear = true }),
  callback = function(e)
    if e.data.kind == "install" or e.data.kind == "update" then
      vim.cmd.packadd({ args = { e.data.spec.name }, bang = false })
      vim.defer_fn(function()
        require("blink.cmp.fuzzy.build").build()
      end, 200)
    end
  end,
})

vim.api.nvim_create_autocmd("PackChanged", {
  pattern = "nvim-treesitter",
  desc = "Run `:TSUpdate` after pack update",
  group = vim.api.nvim_create_augroup("ts_update", { clear = true }),
  callback = function(e)
    if e.data.kind == "update" then
      require("nvim-treesitter").update()
    end
  end,
})

vim.pack.add({
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/akinsho/git-conflict.nvim" },
  { src = "https://github.com/Saghen/blink.cmp", version = "main" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
  { src = "https://github.com/nvim-mini/mini.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  { src = "https://github.com/Wansmer/treesj" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/igorlfs/nvim-dap-view" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
})

-- -- Colorscheme

local hl_get = function(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  desc = "Add highlights for `mini.hipatterns`",
  group = vim.api.nvim_create_augroup("minihipatterns_update", { clear = true }),
  callback = function()
    local hl = function(name, fg, bg)
      vim.api.nvim_set_hl(0, name, { bold = true, fg = fg, bg = bg })
    end
    hl("UserHipatternsPerf", "black", hl_get("Identifier").fg)
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  desc = "Add text highlight for `LspProgress` notify window",
  group = vim.api.nvim_create_augroup("lsp_progress_hl", { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "LspProgress", { default = true, link = "Comment" })
  end,
})

require("tokyonight").setup({
  on_highlights = function(hl, c)
    -- hl.DiagnosticUnnecessary = {}
    hl.LspProgress = { fg = c.comment }
  end,
})

vim.g.default_colors = "tokyonight-night"

vim.cmd.rshada()
if pcall(vim.cmd.colorscheme, vim.g.COLORS_NAME) then
  vim.o.background = vim.g.COLORS_BG or "dark"
end

-- -- Completion

require("blink.cmp").setup({
  keymap = {
    ["<C-n>"] = { "show_and_insert", "select_next" },
    ["<C-p>"] = { "show_and_insert", "select_prev" },
    ["<C-j>"] = { "select_and_accept" },
  },
})

vim.keymap.set("i", "<C-x><C-o>", function()
  require("blink.cmp").show()
  require("blink.cmp").show_documentation()
  require("blink.cmp").hide_documentation()
end, { desc = "Show completion" })

-- -- Markdown

require("render-markdown").setup({
  checkbox = { enabled = false },
  code = { sign = false, width = "full" },
  heading = { icons = {} },
})

-- -- Mini

local MiniAi = require("mini.ai")
MiniAi.setup({
  mappings = {
    around_next = "",
    inside_next = "",
    around_last = "",
    inside_last = "",
    goto_left = "g[",
    goto_right = "g]",
  },
  custom_textobjects = {
    B = MiniAi.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
    C = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    F = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    I = MiniAi.gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
    L = MiniAi.gen_spec.treesitter({ a = "@loop.outer", i = "@loop.inner" }),
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
            "%f[%a_%-]%l+%d*[_%-]*",
            "%f[%w_%-]%d+[_%-]*",
            "%f[%u_%-]%u%f[%A]%d*[_%-]*",
            "%f[%u_%-]%u%l+%d*[_%-]*",
            "%f[%u_%-]%u%u+%d*[_%-]*",
            -- __pattern
            "%f[_%-][_%-]+%l+%d*",
            "%f[_%-][_%-]+%d+",
            "%f[_%-][_%-]+%u%f[%A]%d*",
            "%f[_%-][_%-]+%u%l+%d*",
            "%f[_%-][_%-]+%u%u+%d*",
            -- __pattern__
            "[_%-]()()%l+%d*[_%-]+()()",
            "[_%-]()()%d+[_%-]+()()",
            "[_%-]()()%u%f[%A]%d*[_%-]+()()",
            "[_%-]()()%u%l+%d*[_%-]+()()",
            "[_%-]()()%u%u+%d*[_%-]+()()",
          },
        }
      end
      if ai_type == "i" then
        local reg = MiniAi.find_textobject("a", id, opts)
        if reg then
          local line = vim.fn.getline(reg.from.line)
          local _, s = line:find("^[_%-]*.", reg.from.col)
          local e = line:sub(1, reg.to.col):find(".[_%-]*$")
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
-- -- MiniAi: Subword jump
local ai_jump = function(side, where, search_method)
  local ai_type, id = where:sub(1, 1), where:sub(2, 2)
  MiniAi.move_cursor(side, ai_type, id, { n_times = vim.v.count1, search_method = search_method })
end
-- stylua: ignore
vim.keymap.set("n", ",e", function() ai_jump("left", "ie", "cover_or_next") end, { desc = "Next subword" })
-- stylua: ignore
vim.keymap.set("n", ",E", function() ai_jump("left", "ie", "prev") end, { desc = "Prev subword" })

local MiniSurround = require("mini.surround")
local surround_sel = function()
  local mark1, mark2
  if vim.v.operator == ":" then
    mark1, mark2 = "<", ">"
  else
    mark1, mark2 = "[", "]"
  end
  local pos1 = vim.api.nvim_buf_get_mark(0, mark1)
  local pos2 = vim.api.nvim_buf_get_mark(0, mark2)
  local text = vim.api.nvim_buf_get_text(0, pos1[1] - 1, pos1[2], pos2[1] - 1, pos2[2] + 1, {})
  return text, pos1, pos2
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
    l = {
      output = function()
        if vim.b.minisurround_log_insert then
          local sel_lines = surround_sel()
          local sel = vim.trim(table.concat(sel_lines, "\n"))
          local row = vim.fn.line(".")
          local log = string.format(vim.b.minisurround_log_insert, sel, sel)
          vim.api.nvim_buf_set_lines(0, row, row, true, { log })
          vim.cmd("normal j==0^")
        end
      end,
    },
  },
})

local MiniClue = require("mini.clue")
vim.keymap.set("n", "<C-w>rq", "<nop>", { desc = "Quit" })
vim.keymap.set("n", "<C-w>rH", "<C-w>h", { remap = true, desc = "Move left" })
vim.keymap.set("n", "<C-w>rJ", "<C-w>j", { remap = true, desc = "Move down" })
vim.keymap.set("n", "<C-w>rK", "<C-w>k", { remap = true, desc = "Move up" })
vim.keymap.set("n", "<C-w>rL", "<C-w>l", { remap = true, desc = "Move right" })
local resize = function(dir)
  local step = { h = 4, v = 2 }
  if dir == "h" then
    vim.fn.win_move_separator(vim.fn.winnr("h"), -step.h)
  elseif dir == "l" then
    vim.fn.win_move_separator(vim.fn.winnr("h"), step.h)
  elseif dir == "k" then
    vim.fn.win_move_statusline(vim.fn.winnr("k"), -step.v)
  elseif dir == "j" then
    vim.fn.win_move_statusline(vim.fn.winnr("k"), step.v)
  end
end
-- stylua: ignore start
vim.keymap.set("n", "<C-w>rh", function() resize("h") end, { desc = "Resize left" })
vim.keymap.set("n", "<C-w>rj", function() resize("j") end, { desc = "Resize down" })
vim.keymap.set("n", "<C-w>rk", function() resize("k") end, { desc = "Resize up" })
vim.keymap.set("n", "<C-w>rl", function() resize("l") end, { desc = "Resize right" })
-- stylua: ignore end
MiniClue.gen_clues.resize = function()
  return {
    { mode = "n", keys = "<C-w>rq" },
    { mode = "n", keys = "<C-w>rH", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rJ", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rK", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rL", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rh", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rj", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rk", postkeys = "<C-w>r" },
    { mode = "n", keys = "<C-w>rl", postkeys = "<C-w>r" },
  }
end
MiniClue.setup({
  triggers = {
    { mode = "n", keys = "<C-w>r" },
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "i", keys = "<C-x>" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
  },
  clues = {
    MiniClue.gen_clues.resize(),
    MiniClue.gen_clues.square_brackets(),
    MiniClue.gen_clues.builtin_completion(),
    MiniClue.gen_clues.g(),
    MiniClue.gen_clues.marks(),
    MiniClue.gen_clues.registers(),
    MiniClue.gen_clues.windows(),
    MiniClue.gen_clues.z(),
  },
})

local MiniDiff = require("mini.diff")
MiniDiff.setup({
  mappings = {
    textobject = "ih",
    -- apply = "gh",
    -- reset = "gH",
    goto_prev = "[h",
    goto_next = "]h",
  },
})
local hunk_action = function(mode)
  return function()
    return MiniDiff.operator(mode) .. MiniDiff.config.mappings.textobject
  end
end
vim.keymap.set("n", "gh", hunk_action("apply"), { expr = true, remap = true, desc = "Apply hunk" })
vim.keymap.set("n", "gH", hunk_action("reset"), { expr = true, remap = true, desc = "Reset hunk" })

local MiniFiles = require("mini.files")
MiniFiles.setup({
  windows = {
    width_preview = 100,
  },
})
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
-- stylua: ignore
vim.keymap.set("n", "<Leader>F", function() MiniFiles.open() end, { desc = "Open files" })
vim.api.nvim_create_augroup("mini_files", { clear = true })
local files_main = nil
local files_open = MiniFiles.open
MiniFiles.open = function(...)
  if vim.bo.ft ~= "minifiles" then
    files_main = vim.api.nvim_get_current_buf()
  end
  return files_open(...)
end
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerOpen",
  group = "mini_files",
  callback = function()
    if files_main then
      set_bookmark("%", vim.api.nvim_buf_get_name(files_main), { desc = "Entry file" })
    end
    set_bookmark("@", vim.fn.getcwd, { desc = "Cwd" })
    set_bookmark("n", vim.fn.stdpath("config") .. "/init.lua", { desc = "Config" })
    set_bookmark("p", vim.fn.stdpath("data") .. "/site/pack/core/opt", { desc = "Plugins" })
  end,
})
MiniFiles.actions = {
  toggle_preview = function()
    local preview = MiniFiles.config.windows.preview
    local preview_next = not preview
    MiniFiles.config.windows.preview = preview_next
    MiniFiles.refresh({ windows = { preview = preview_next } })
    if preview then
      local branch = MiniFiles.get_explorer_state().branch
      table.remove(branch)
      MiniFiles.set_branch(branch)
    end
  end,
  search_files = function()
    local minipick = require("mini.pick")
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local parent = vim.fn.fnamemodify(entry.path, ":h")
    minipick.builtin.files(nil, { source = { cwd = parent } })
  end,
  search_grep = function()
    local minipick = require("mini.pick")
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local parent = vim.fn.fnamemodify(entry.path, ":h")
    minipick.builtin.grep({ pattern = "." }, { source = { cwd = parent } })
  end,
}

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  group = "mini_files",
  callback = function(e)
    local buf_map = function(mode, lhs, rhs, opts)
      opts = vim.tbl_extend("keep", opts or {}, { buffer = e.data.buf_id })
      vim.keymap.set(mode, lhs, rhs, opts)
    end
    -- stylua: ignore start
    buf_map("n", "<M-p>", function() MiniFiles.actions.toggle_preview() end, { desc = "Toggle preview" })
    buf_map("n", "<Leader>sg", function() MiniFiles.actions.search_grep() end, { desc = "Search grep" })
    buf_map("n", "<Leader>sf", function() MiniFiles.actions.search_files() end, { desc = "Search files" })
    -- stylua: ignore end
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesWindowUpdate",
  group = "mini_files",
  callback = function(e)
    local win = e.data.win_id
    vim.wo[win].number = true
    vim.wo[win].relativenumber = true
  end,
})

local MiniGit = require("mini.git")
MiniGit.setup()
vim.cmd.cnoreabbrev("G", "Git")
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

local MiniHipatterns = require("mini.hipatterns")
local hi_todo = function(words, hl_name)
  local pattern = vim
    .iter(words)
    :map(function(word)
      return { "()%f[%w]" .. word .. "%f[%W]()", "() " .. word .. "[: ]()" }
    end)
    :flatten()
    :totable()
  return {
    pattern = pattern,
    group = function(b, _, d)
      local parser = vim.treesitter.get_parser(b, nil, { error = false })
      if not parser then
        return
      end
      local node = parser:named_node_for_range({
        d.line - 1,
        d.from_col - 1,
        d.line - 1,
        d.to_col - 1,
      })
      if node and node:type() == "comment_content" then
        return hl_name
      end
    end,
  }
end
local tw_store = {
  hl = {},
  -- stylua: ignore
  cl = {
    slate={[50]="f8fafc",[100]="f1f5f9",[200]="e2e8f0",[300]="cbd5e1",[400]="94a3b8",
    [500]="64748b",[600]="475569",[700]="334155",[800]="1e293b",[900]="0f172a",[950]="020617"},
    gray={[50]="f9fafb",[100]="f3f4f6",[200]="e5e7eb",[300]="d1d5db",[400]="9ca3af",
    [500]="6b7280",[600]="4b5563",[700]="374151",[800]="1f2937",[900]="111827",[950]="030712"},
    zinc={[50]="fafafa",[100]="f4f4f5",[200]="e4e4e7",[300]="d4d4d8",[400]="a1a1aa",
    [500]="71717a",[600]="52525b",[700]="3f3f46",[800]="27272a",[900]="18181b",[950]="09090B"},
    neutral={[50]="fafafa",[100]="f5f5f5",[200]="e5e5e5",[300]="d4d4d4",[400]="a3a3a3",
    [500]="737373",[600]="525252",[700]="404040",[800]="262626",[900]="171717",[950]="0a0a0a"},
    stone={[50]="fafaf9",[100]="f5f5f4",[200]="e7e5e4",[300]="d6d3d1",[400]="a8a29e",
    [500]="78716c",[600]="57534e",[700]="44403c",[800]="292524",[900]="1c1917",[950]="0a0a0a"},
    red={[50]="fef2f2",[100]="fee2e2",[200]="fecaca",[300]="fca5a5",[400]="f87171",
    [500]="ef4444",[600]="dc2626",[700]="b91c1c",[800]="991b1b",[900]="7f1d1d",[950]="450a0a"},
    orange={[50]="fff7ed",[100]="ffedd5",[200]="fed7aa",[300]="fdba74",[400]="fb923c",
    [500]="f97316",[600]="ea580c",[700]="c2410c",[800]="9a3412",[900]="7c2d12",[950]="431407"},
    amber={[50]="fffbeb",[100]="fef3c7",[200]="fde68a",[300]="fcd34d",[400]="fbbf24",
    [500]="f59e0b",[600]="d97706",[700]="b45309",[800]="92400e",[900]="78350f",[950]="451a03"},
    yellow={[50]="fefce8",[100]="fef9c3",[200]="fef08a",[300]="fde047",[400]="facc15",
    [500]="eab308",[600]="ca8a04",[700]="a16207",[800]="854d0e",[900]="713f12",[950]="422006"},
    lime={[50]="f7fee7",[100]="ecfccb",[200]="d9f99d",[300]="bef264",[400]="a3e635",
    [500]="84cc16",[600]="65a30d",[700]="4d7c0f",[800]="3f6212",[900]="365314",[950]="1a2e05"},
    green={[50]="f0fdf4",[100]="dcfce7",[200]="bbf7d0",[300]="86efac",[400]="4ade80",
    [500]="22c55e",[600]="16a34a",[700]="15803d",[800]="166534",[900]="14532d",[950]="052e16"},
    emerald={[50]="ecfdf5",[100]="d1fae5",[200]="a7f3d0",[300]="6ee7b7",[400]="34d399",
    [500]="10b981",[600]="059669",[700]="047857",[800]="065f46",[900]="064e3b",[950]="022c22"},
    teal={[50]="f0fdfa",[100]="ccfbf1",[200]="99f6e4",[300]="5eead4",[400]="2dd4bf",
    [500]="14b8a6",[600]="0d9488",[700]="0f766e",[800]="115e59",[900]="134e4a",[950]="042f2e"},
    cyan={[50]="ecfeff",[100]="cffafe",[200]="a5f3fc",[300]="67e8f9",[400]="22d3ee",
    [500]="06b6d4",[600]="0891b2",[700]="0e7490",[800]="155e75",[900]="164e63",[950]="083344"},
    sky={[50]="f0f9ff",[100]="e0f2fe",[200]="bae6fd",[300]="7dd3fc",[400]="38bdf8",
    [500]="0ea5e9",[600]="0284c7",[700]="0369a1",[800]="075985",[900]="0c4a6e",[950]="082f49"},
    blue={[50]="eff6ff",[100]="dbeafe",[200]="bfdbfe",[300]="93c5fd",[400]="60a5fa",
    [500]="3b82f6",[600]="2563eb",[700]="1d4ed8",[800]="1e40af",[900]="1e3a8a",[950]="172554"},
    indigo={[50]="eef2ff",[100]="e0e7ff",[200]="c7d2fe",[300]="a5b4fc",[400]="818cf8",
    [500]="6366f1",[600]="4f46e5",[700]="4338ca",[800]="3730a3",[900]="312e81",[950]="1e1b4b"},
    violet={[50]="f5f3ff",[100]="ede9fe",[200]="ddd6fe",[300]="c4b5fd",[400]="a78bfa",
    [500]="8b5cf6",[600]="7c3aed",[700]="6d28d9",[800]="5b21b6",[900]="4c1d95",[950]="2e1065"},
    purple={[50]="faf5ff",[100]="f3e8ff",[200]="e9d5ff",[300]="d8b4fe",[400]="c084fc",
    [500]="a855f7",[600]="9333ea",[700]="7e22ce",[800]="6b21a8",[900]="581c87",[950]="3b0764"},
    fuchsia={[50]="fdf4ff",[100]="fae8ff",[200]="f5d0fe",[300]="f0abfc",[400]="e879f9",
    [500]="d946ef",[600]="c026d3",[700]="a21caf",[800]="86198f",[900]="701a75",[950]="4a044e"},
    pink={[50]="fdf2f8",[100]="fce7f3",[200]="fbcfe8",[300]="f9a8d4",[400]="f472b6",
    [500]="ec4899",[600]="db2777",[700]="be185d",[800]="9d174d",[900]="831843",[950]="500724"},
    rose={[50]="fff1f2",[100]="ffe4e6",[200]="fecdd3",[300]="fda4af",[400]="fb7185",
    [500]="f43f5e",[600]="e11d48",[700]="be123c",[800]="9f1239",[900]="881337",[950]="4c0519"},
  },
}
vim.api.nvim_create_autocmd("ColorScheme", {
  desc = "Reset tailwind hl-store on colorscheme change",
  group = vim.api.nvim_create_augroup("reset_tailwind_hl", { clear = true }),
  callback = function()
    tw_store.hl = {}
  end,
})
local minihipatterns_config = {
  highlighters = {
    fix = hi_todo({ "FIX", "FIXME", "BUG" }, "MiniHipatternsFixme"),
    note = hi_todo({ "NOTE" }, "MiniHipatternsNote"),
    todo = hi_todo({ "TODO", "FEAT" }, "MiniHipatternsTodo"),
    hack = hi_todo({ "WARN", "WARNING", "HACK" }, "MiniHipatternsHack"),
    perf = hi_todo({ "PERF" }, "UserHipatternsPerf"),
    hex_color = MiniHipatterns.gen_highlighter.hex_color(),
    hex_color_short = {
      pattern = "()#%x%x%x()%f[^%x%w]",
      group = function(_, _, data)
        local match = data.full_match
        local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
        local hex_color = "#" .. r .. r .. g .. g .. b .. b
        return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
      end,
    },
    hsl_color = {
      -- NOTE: Partial support for CSS hsl()
      pattern = "hsl%(%d+[, ] ?%d+%%?[, ] ?%d+%%?%)",
      group = function(_, m, _)
        -- https://www.w3.org/TR/css-color-3/#hsl-color
        local function hsl_to_rgb(h, s, l)
          h, s, l = h % 360, s / 100, l / 100
          if h < 0 then
            h = h + 360
          end
          local function f(n)
            local k = (n + h / 30) % 12
            local a = s * math.min(l, 1 - l)
            return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
          end
          return f(0) * 255, f(8) * 255, f(4) * 255
        end
        local h, s, l = m:match("(%d+)[, ] ?(%d+)%%?[, ] ?(%d+)%%?")
        local r, g, b = hsl_to_rgb(h, s, l)
        local hex = string.format("#%02x%02x%02x", r, g, b)
        return MiniHipatterns.compute_hex_color_group(hex)
      end,
    },
    tailwind = {
      pattern = function()
        local ft = {
          "css",
          "html",
          "javascript",
          "javascriptreact",
          "svelte",
          "typescript",
          "typescriptreact",
          "vue",
        }
        if not vim.tbl_contains(ft, vim.bo.filetype) then
          return
        end
        return "%f[%w:-]()[%w:-]+%-[a-z%-]+%-%d+()%f[^%w:-]"
        -- compact
        -- return "%f[%w:-][%w:-]+%-()[a-z%-]+%-%d+()%f[^%w:-]"
      end,
      group = function(_, _, d)
        local match = d.full_match
        local color, shade = match:match("[%w-]+%-([a-z%-]+)%-(%d+)")
        shade = tonumber(shade)
        local bg = vim.tbl_get(tw_store.cl, color, shade)
        if bg then
          local hl = "MiniHipatternsTailwind" .. color .. shade
          if not tw_store.hl[hl] then
            tw_store.hl[hl] = true
            local bg_shade = shade == 500 and 950 or shade < 500 and 900 or 100
            local fg = vim.tbl_get(tw_store.cl, color, bg_shade)
            vim.api.nvim_set_hl(0, hl, { bg = "#" .. bg, fg = "#" .. fg })
          end
          return hl
        end
      end,
    },
  },
}
vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Setup `mini.hipatterns`",
  group = vim.api.nvim_create_augroup("minihipatterns_setup", { clear = true }),
  callback = function()
    MiniHipatterns.setup(minihipatterns_config)
  end,
})

local MiniIndentscope = require("mini.indentscope")
vim.g.miniindentscope_disable = true
MiniIndentscope.setup({
  mappings = {
    object_scope = "ii",
    object_scope_with_border = "ai",
    goto_top = "[i",
    goto_bottom = "]i",
  },
  options = {
    indent_at_cursor = false,
  },
})
vim.keymap.set("n", "[I", "100[i", { remap = true, desc = "Indent first" })
vim.keymap.set("n", "]I", "100]i", { remap = true, desc = "Indent last" })
vim.keymap.set("n", "grs", function()
  vim.cmd("sil norm " .. string.rep("[i", vim.v.count - 1) .. "viiy']vaiopgv<")
end, { desc = "Unscope" })

local MiniJump2d = require("mini.jump2d")
MiniJump2d.setup({ mappings = { start_jumping = "" } })
vim.keymap.set("n", "<S-Enter>", function()
  MiniJump2d.start(MiniJump2d.builtin_opts.query)
end, { desc = "Jump2d" })

-- local MiniKeymap = require("mini.keymap")
-- MiniKeymap.map_combo("i", ">", function()
--   local row, col = unpack(vim.api.nvim_win_get_cursor(0))
--   local line = vim.api.nvim_get_current_line()
--   if line:sub(col + 1, col + 1) == "<" then
--     return
--   end
--   local tag = line:sub(1, col):match("<([%l%d:%-]+)[^<>]*>$")
--   if not tag then
--     return
--   end
--   local close = ("</%s>"):format(tag)
--   row = row - 1
--   vim.api.nvim_buf_set_text(0, row, col, row, col, { close })
-- end)

local MiniMisc = require("mini.misc")
MiniMisc.setup_restore_cursor({ center = vim.g.session_center })

local MiniSessions = require("mini.sessions")
function _G.find_root(buf)
  return vim.fs.root(buf or 0, vim.g.session_root or {})
end
local root_session = function()
  local root = find_root()
  local ignore = function(path)
    return vim.iter({ "/", "~" }):any(function(p)
      return vim.fs.normalize(p) == vim.fs.normalize(path)
    end)
  end
  if not root or ignore(root) then
    root = vim.fn.getcwd()
  end
  local relpath = vim.fs.relpath("~", root)
  if relpath and relpath ~= "." then
    root = relpath
  end
  local name = string.gsub(root, "/", "%%")
  return name
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
        if vim.g.session_center then
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
vim.api.nvim_create_user_command("Load", function()
  ncall("WARN", MiniSessions.read, root_session())
end, {})
vim.api.nvim_create_user_command("Save", function()
  ncall("WARN", MiniSessions.write, root_session())
end, {})
vim.api.nvim_create_user_command("Last", function()
  ncall("WARN", MiniSessions.read, MiniSessions.get_latest())
end, {})
--
local load_au = vim.api.nvim_create_augroup("session_load", { clear = true })
local save_au = vim.api.nvim_create_augroup("session_save", { clear = true })
-- -- -- Load
if vim.fn.argc() == 0 then
  vim.api.nvim_create_autocmd("VimEnter", {
    desc = "Load session on `vim` with no args",
    group = load_au,
    nested = true,
    callback = function()
      vim.cmd("silent Load")
    end,
  })
end
-- -- -- Save
vim.api.nvim_create_autocmd("VimLeave", {
  desc = "Save session on `VimLeave`",
  group = save_au,
  callback = function()
    local non_float = vim.tbl_filter(function(win)
      local config = vim.api.nvim_win_get_config(win)
      return config.relative == ""
    end, vim.api.nvim_list_wins())
    if #non_float == 0 then
      return
    end
    if #non_float == 1 then
      local win = non_float[1]
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_name(buf) == "" then
        return
      end
    end
    vim.cmd("silent Save")
  end,
})

local MiniMove = require("mini.move")
MiniMove.setup({
  mappings = {
    left = "<C-h>",
    down = "<C-j>",
    up = "<C-k>",
    right = "<C-l>",
    line_left = "",
    line_down = "",
    line_up = "",
    line_right = "",
  },
})

local MiniPairs = require("mini.pairs")
MiniPairs.setup({
  mappings = {
    ["("] = { neigh_pattern = "[^\\][%s>)%]},:]" },
    ["["] = { neigh_pattern = "[^\\][%s>)%]},:]" },
    ["{"] = { neigh_pattern = "[^\\][%s>)%]},:]" },
    ['"'] = { neigh_pattern = "[%s<(%[{][%s>)%]},:]" },
    ["'"] = { neigh_pattern = "[%s<(%[{][%s>)%]},:]" },
    ["`"] = { neigh_pattern = "[%s<(%[{][%s>)%]},:]" },
    ["<"] = { action = "open", pair = "<>", neigh_pattern = "[\r%w\"'`].", register = { cr = false } },
    [">"] = { action = "close", pair = "<>", register = { cr = false } },
  },
})
require("mini.keymap").map_combo("i", "<", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  return line:sub(col - 2, col) == "<<>" and "<Del>" or nil
end)
require("mini.keymap").map_combo("i", "=", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  return line:sub(col - 2, col) == "<=>" and "<Del>" or nil
end)

local MiniExtra = require("mini.extra")
MiniExtra.setup()

local MiniPick = require("mini.pick")
local pick_remap = function(char, keys)
  return {
    char = char,
    func = function()
      vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
    end,
  }
end
MiniPick.registry.colorschemes = function(local_opts, opts)
  local aug = vim.api.nvim_create_augroup("pick_colors", { clear = true })
  local fake_buf = vim.api.nvim_create_buf(false, true)
  local cl = vim.g.colors_name or "default"
  local bg = vim.o.background
  local preview = function(colors)
    local item = colors or MiniPick.get_picker_matches().current
    local func = MiniPick.get_picker_opts().source.preview
    pcall(func, fake_buf, item)
    vim.o.background = bg
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
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniPickStart",
    group = aug,
    callback = function()
      match_current()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniPickMatch",
    group = aug,
    callback = function()
      vim.schedule(preview)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniPickStop",
    group = aug,
    once = true,
    callback = function()
      vim.api.nvim_clear_autocmds({ group = aug })
      vim.api.nvim_buf_delete(fake_buf, { unload = true })
    end,
  })
  local on_move = function()
    vim.schedule(preview)
  end
  local remap_move = function(char, keys)
    return {
      char = char,
      func = function()
        vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
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
        move_start = "<Home>",
        scroll_down = "<PageDown>",
        scroll_up = "<PageUp>",
        move_down_alt = remap_move("<C-n>", "<Down>"),
        move_up_alt = remap_move("<C-p>", "<Up>"),
        move_start_alt = remap_move("<C-g>", "<Home>"),
        scroll_down_alt = remap_move("<C-f>", "<PageDown>"),
        scroll_up_alt = remap_move("<C-b>", "<PageUp>"),
        match_current = {
          char = "<C-0>",
          func = function()
            match_current()
            on_move()
          end,
        },
        change_bg = {
          char = "<Tab>",
          func = function()
            bg = vim.o.background == "dark" and "light" or "dark"
            vim.o.background = bg
          end,
        },
      },
    })
  )
end
local lang_bufs = {}
local get_code_highlights = function(code, ft)
  local lang = vim.treesitter.language.get_lang(ft or "")
  if
    not lang
    or not vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false)
    or not vim.api.nvim_get_runtime_file("queries/" .. lang .. "/highlights.scm", false)
  then
    return {}
  end
  local buf = lang_bufs[lang]
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    ---@cast buf integer
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "mini.pick://picker/highlight/" .. lang)
    lang_bufs[lang] = buf
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, code)
  local parser = vim.treesitter.get_parser(buf, lang, { error = false })
  if not parser then
    return {}
  end
  parser:parse(true)
  -- NOTE: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/util/highlight.lua#L7-L110
  local ret = {}
  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end
    local query = vim.treesitter.query.get(tree:lang(), "highlights")
    if not query then
      return
    end
    for capture, node, metadata in query:iter_captures(tstree:root(), buf) do
      ---@type string
      local name = query.captures[capture]
      if name ~= "spell" then
        local range = { node:range() } ---@type number[]
        local multi = range[1] ~= range[3]
        local text = multi
            and vim.split(vim.treesitter.get_node_text(node, buf, metadata[capture]), "\n", { plain = true })
          or {}
        for row = range[1] + 1, range[3] + 1 do
          local first, last = row == range[1] + 1, row == range[3] + 1
          local end_col = last and range[4] or #(text[row - range[1]] or "")
          end_col = multi and first and end_col + range[2] or end_col
          ret[row] = ret[row] or {}
          table.insert(ret[row], {
            col = first and range[2] or 0,
            end_col = end_col,
            priority = (tonumber(metadata.priority or metadata[capture] and metadata[capture].priority) or 100),
            conceal = metadata.conceal or metadata[capture] and metadata[capture].conceal,
            hl_group = "@" .. name .. "." .. lang,
          })
        end
      end
    end
  end)
  return ret
end
local grep_ns = vim.api.nvim_create_namespace("minipick_grep")
vim.api.nvim_set_hl(0, "MiniPickMatchRanges", { bold = true, underdotted = true })
local grep_cache = {}
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniPickStop",
  callback = function()
    grep_cache = {}
  end,
})
local minipick_grep_show = function(buf, data, query, opts)
  vim.api.nvim_buf_clear_namespace(buf, grep_ns, 0, -1)
  -- Default show
  MiniPick.default_show(buf, data, query, opts)
  -- Syntax highlight
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  for ln in ipairs(data) do
    local line = lines[ln]
    local file, row, col, code = unpack(vim.split(data[ln], "%z"))
    local ft = vim.filetype.match({ filename = file }) or ""
    -- Get highlights +cache
    local cache_id = string.format("%s|%s|%s", file, row, col)
    local line_hls = grep_cache[cache_id]
    if not line_hls then
      line_hls = get_code_highlights({ code }, ft)[1]
      grep_cache[cache_id] = line_hls
    end
    if line_hls then
      line_hls = vim.deepcopy(line_hls, true)
      local _, off = string.find(line, ".*│.*│.*│")
      local extm_row = ln - 1
      for _, hl in ipairs(line_hls) do
        local extm_col = off + hl.col
        hl.col = nil
        hl.end_col = off + hl.end_col
        local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, grep_ns, extm_row, extm_col, hl)
        if not ok then
          vim.notify("Set extmark: " .. err, vim.log.levels.WARN)
        end
      end
    end
  end
end
MiniPick.registry.grep = function(local_opts, opts)
  return MiniPick.builtin.grep(
    local_opts,
    vim.tbl_deep_extend("keep", opts or {}, { source = { show = minipick_grep_show } })
  )
end
MiniPick.registry.grep_live = function(local_opts, opts)
  return MiniPick.builtin.grep_live(
    local_opts,
    vim.tbl_deep_extend("keep", opts or {}, { source = { show = minipick_grep_show } })
  )
end
MiniPick.setup({
  -- source = {
  --   show = MiniPick.default_show,
  -- },
  mappings = {
    choose_marked = "<S-Enter>",
    move_down_2 = pick_remap("<C-j>", "<C-n>"),
    move_up_2 = pick_remap("<C-k>", "<C-p>"),
    quckfix = {
      char = "<C-q>",
      func = function()
        local marked = MiniPick.get_picker_matches().marked
        if not vim.tbl_isempty(marked) then
          return MiniPick.default_choose_marked(marked, { list_type = "quickfix" })
        end
      end,
    },
    reveal_file = {
      char = "<C-o>",
      func = function()
        local is_file = function(item)
          local ok, stat = pcall(vim.uv.fs_stat, item)
          return ok and stat ~= nil
        end
        local matches = MiniPick.get_picker_matches()
        local current = matches.current
        if not is_file(current) then
          return
        end
        vim.schedule(function()
          local minifiles = require("mini.files")
          minifiles.open(current, false)
          minifiles.reveal_cwd()
        end)
        return true
      end,
    },
  },
})
vim.keymap.set("n", "<Leader>sf", function()
  MiniPick.builtin.cli({
    command = { "fd", "-t=f", "-H", "-I", "-E=.git", "-E=node_modules" },
  }, {
    source = {
      name = "Files (fd)",
      show = function(buf, items, query)
        MiniPick.default_show(buf, items, query, { show_icons = true })
      end,
    },
  })
end, { desc = "Seach files" })
-- stylua: ignore start
vim.keymap.set("n", "<Leader>sb", function() MiniPick.registry.buffers() end, { desc = "Seach buffers" })
vim.keymap.set("n", "<Leader>sg", function() MiniPick.registry.grep_live() end, { desc = "Seach grep" })
vim.keymap.set("n", "<Leader>sh", function() MiniPick.registry.help() end, { desc = "Seach help" })
vim.keymap.set("n", "<Leader>sm", function() MiniPick.registry.git_hunks() end, { desc = "Seach hunks" })
vim.keymap.set("n", "<Leader>sr", function() MiniPick.registry.resume() end, { desc = "Seach resume" })
-- NOTE: MiniExtra
vim.keymap.set("n", "<Leader>sc", function() MiniPick.registry.colorschemes() end, { desc = "Search colorschemes" })
-- stylua: ignore end

-- -- Treesitter

vim.treesitter.language.register("tsx", "typescriptreact")

local ts_install = vim.g.ts_install or {}
local ts_filetypes = vim
  .iter(ts_install)
  :map(function(lang)
    return vim.treesitter.language.get_filetypes(lang)
  end)
  :flatten()
  :totable()

require("nvim-treesitter").install(ts_install)

local ts_swap = require("nvim-treesitter-textobjects.swap")
-- stylua: ignore
vim.keymap.set("n", "<Leader>a", function() ts_swap.swap_next("@parameter.inner") end, { desc = "Swap arg next" })
-- stylua: ignore
vim.keymap.set("n", "<Leader>A", function() ts_swap.swap_previous("@parameter.inner") end, { desc = "Swap arg prev" })

vim.api.nvim_create_autocmd("FileType", {
  desc = "Setup treesitter for a buffer",
  pattern = ts_filetypes,
  group = vim.api.nvim_create_augroup("ts_setup", { clear = true }),
  callback = function(e)
    vim.treesitter.start(e.buf)
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- -- Treesj

require("treesj").setup({ max_join_length = 750, use_default_keymaps = false })
-- stylua: ignore
vim.keymap.set("n", "gS", function() require("treesj").toggle() end)

-- -- Mason

local mason_install = vim.g.mason_install or {}
require("mason").setup()
local mason_available = require("mason-registry").get_installed_package_names()
local mason_rest = {}
for _, inst in ipairs(mason_install) do
  if not vim.list_contains(mason_available, inst) then
    table.insert(mason_rest, inst)
  end
end
if #mason_rest > 0 then
  vim.cmd("MasonInstall " .. table.concat(mason_rest, " "))
end

-- -- LSP

local lsp_enable = vim.g.lsp_enable or {}
vim.lsp.enable(lsp_enable)
vim.diagnostic.config({ virtual_text = true })

vim.keymap.set("n", "gK", function()
  local state = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = state, underline = state })
end, { desc = "Toggle diagnostic" })

vim.keymap.set("n", "gI", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay" })

-- -- -- Inlay hints

-- vim.api.nvim_create_autocmd("LspAttach", {
--   desc = "Enable inlay hints",
--   group = vim.api.nvim_create_augroup("inlay_hints", { clear = true }),
--   callback = function(e)
--     local client = assert(vim.lsp.get_client_by_id(e.data.client_id))
--     if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
--       vim.lsp.inlay_hint.enable(true, { bufnr = e.buf })
--     end
--   end,
-- })

-- -- -- Undim current diagnostic

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
--
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

-- -- -- Lsp progress

do
  local au = vim.api.nvim_create_augroup("lsp_progress", { clear = true })
  local ns = vim.api.nvim_create_namespace("lsp_progress")
  local timer = assert(vim.uv.new_timer())
  local buf = -1
  local win = -1
  -- Utils
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
  -- Notify
  local lsp_notify = function(lines, hl, keep_ms)
    hl = hl or "Comment"
    keep_ms = keep_ms or nil
    if vim.tbl_isempty(lines) then
      return
    end
    local vpad, hpad = 0, 0
    local min_width, min_height = 1, 1
    local max_width, max_height = vim.o.columns / 3, vim.o.lines - 5
    --
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
    -- Create/update window
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
    --
    local buf_lines = lines
    -- Cut lines
    local cut_edge = vim.api.nvim_win_get_width(win) - hpad * 2
    for i, line in ipairs(buf_lines) do
      buf_lines[i] = text_overflow(line, cut_edge)
    end
    -- Pad lines
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
    -- Set lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
    vim.hl.range(buf, ns, hl, { 0, 0 }, { #buf_lines, -1 })
    -- Shedule closing
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
  -- Setup
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
end

-- -- Debug

local dap = require("dap")
local dap_view = require("dap-view")
dap_view.setup()
require("nvim-dap-virtual-text").setup()

-- stylua: ignore start
vim.keymap.set("n", "<Leader>b", function() dap.toggle_breakpoint() end, { desc = "Breakpoint" })
vim.keymap.set("n", "<Leader>B", function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = "Breakpoint condition" })
vim.keymap.set("n", "<Leader>dc", function() dap.continue() end, { desc = "Run/continue" })
vim.keymap.set("n", "<Leader>dp", function() dap.pause() end, { desc = "Pause" })
vim.keymap.set("n", "<Leader>di", function() dap.step_into() end, { desc = "Step into" })
vim.keymap.set("n", "<Leader>do", function() dap.step_over() end, { desc = "Step over" })
vim.keymap.set("n", "<Leader>dO", function() dap.step_out() end, { desc = "Step out" })
vim.keymap.set("n", "<Leader>db", function() dap.step_back() end, { desc = "Debug step back" })
vim.keymap.set("n", "<Leader>df", function() dap.restart_frame() end, { desc = "Debug step back" })
vim.keymap.set("n", "<Leader>dl", function() dap.run_last() end, { desc = "Run Last" })
vim.keymap.set("n", "<Leader>dq", function() dap.terminate() end, { desc = "Terminate" })
vim.keymap.set("n", "<Leader>de", function() dap.eval(nil, { enter = true }) end, { desc = "Eval" })
vim.keymap.set("n", "<Leader>dw", function() dap_view.toggle() end, { desc = "Widgets" })
-- stylua: ignore end

-- vim.keymap.set("n", "<Leader>dq", "<nop>", { desc = "Quit" })
-- MiniClue.gen_clues.debug = function()
--   return {
--     { mode = "n", keys = "<Leader>dq" },
--     { mode = "n", keys = "<Leader>dc", postkeys = "<Leader>d" },
--   }
-- end
-- vim.list_extend(MiniClue.config.triggers, { mode = "n", keys = "<Leader>d" })
-- vim.list_extend(MiniClue.config.clues, MiniClue.gen_clues.debug())

-- stylua: ignore start
dap.listeners.before.attach.dapui_config = function() dap.view.open() end
dap.listeners.before.launch.dapui_config = function() dap.view.open() end
dap.listeners.before.event_terminated.dapui_config = function() dap_view.close() end
dap.listeners.before.event_exited.dapui_config = function() dap_view.close() end
-- stylua: ignore end

-- -- -- Go

-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#go-using-delve-directly
dap.adapters.delve = function(callback, config)
  if config.mode == "remote" and config.request == "attach" then
    callback({
      type = "server",
      host = config.host or "127.0.0.1",
      port = config.port or "38697",
    })
  else
    callback({
      type = "server",
      port = "${port}",
      executable = {
        command = "dlv",
        args = { "dap", "-l", "127.0.0.1:${port}", "--log", "--log-output=dap" },
        detached = vim.fn.has("win32") == 0,
      },
    })
  end
end
dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}",
  },
  {
    type = "delve",
    name = "Debug test",
    request = "launch",
    mode = "test",
    program = "${file}",
  },
  {
    type = "delve",
    name = "Debug test (go.mod)",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}",
  },
}

-- Custom

-- -- Format

---@class FormatOpts
---@field cmd string[]
---@field stdin? [integer,integer]
---@field range? [integer,integer]
---@field transform? fun(out: string): string[]
---@field diff? "any"|"none"|"overlap"|"contain"
---@field diff_algorithm? "myers"|"minimal"|"patience"|"histogram"
---@field timeout? integer

---@param buf? integer
---@param opts? FormatOpts
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
      vim.notify(string.format("-%s- %s", cmd[1], out.stderr), vim.log.levels.ERROR)
    end
  end)
  local sysopts = { ---@type vim.SystemOpts
    stdin = lines,
    text = true,
    cwd = vim.fs.dirname(file),
    timeout = opts.timeout,
  }
  return vim.system(cmd, sysopts, on_exit)
end

local format = function(range)
  range = range or {}
  local formatconf = vim.g.formatconf or {}
  local conf = formatconf[vim.bo.ft]
  if not vim.is_callable(conf) then
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
  ---@diagnostic disable-next-line: redundant-parameter
  local fmt_opts = conf(line1, line2)
  fmt_opts = vim.islist(fmt_opts) and fmt_opts or { fmt_opts }
  for _, opts in ipairs(fmt_opts) do
    opts = vim.tbl_extend("keep", opts, { range = { line1, line2 } })
    format_buf(0, opts):wait()
  end
  return true
end

_G.Formatexpr = function(opts)
  local line1, line2 = vim.v.lnum, vim.v.lnum + vim.v.count
  if format({ line1, line2 }) then
  else
    return vim.lsp.formatexpr(opts)
  end
end

vim.o.formatexpr = "v:lua.Formatexpr()"
-- stylua: ignore
vim.keymap.set("n", "gqag", function() format() end)
-- stylua: ignore
vim.keymap.set("n", "gqga", function() format() end)

-- -- Terminal

vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Set options for the terminal window",
  group = vim.api.nvim_create_augroup("term_open", { clear = true }),
  callback = function()
    vim.wo.number = false
    vim.wo.relativenumber = false
  end,
})

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.cmd.cnoreabbrev("lz", "Lazygit")
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

-- -- -- Count terminal

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
do
  local last_count = 1 ---@type integer?
  local win = -1
  local win_config = { height = 15 }
  local open_term = function(count)
    win = Terminal.open("default", count, win_config)
    vim.wo[win].winbar = "Terminal " .. count
  end
  vim.keymap.set({ "v", "n", "t" }, "<M-`>", function()
    if vim.api.nvim_win_is_valid(win) then
      win_config = vim.api.nvim_win_get_config(win)
      if vim.v.count == 0 then
        last_count = Terminal.close("default", false)
      else
        open_term(vim.v.count1)
      end
    else
      open_term(vim.v.count == 0 and last_count or vim.v.count1)
    end
  end, { desc = "Terminal" })
end

-- -- Marks

local mark_ns = vim.api.nvim_create_namespace("mark_virtual")
local marks_group = vim.api.nvim_create_augroup("mark_virtual", { clear = true })
vim.g.virt_marks = true
local get_marks = function(buf, filter)
  buf = buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local file = vim.api.nvim_buf_get_name(buf)
  filter = filter or function(m)
    return m.mark:match("'%a")
  end
  -- stylua: ignore
  local buffer_marks = vim.iter(vim.fn.getmarklist(buf))
    :map(function(m) m.type = "buffer"; return m end)
    :totable()
  -- stylua: ignore
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
--
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
-- stylua: ignore start
vim.keymap.set("n", "<Leader>m", function() toggle_marks() end, { desc = "Toggle buf marks" })
vim.keymap.set("n", "<Leader>M", function() toggle_marks_all() end, { desc = "Toggle marks" })
-- stylua: ignore end
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

-- -- Checkout (mini.git)

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
