local pack = require("util.pack")

pack.later(function()
  local MiniClue = require("mini.clue")

  local resize_prefix = "<C-w>R"
  vim.keymap.set("n", resize_prefix .. "q", "<nop>", { desc = "Quit" })
  vim.keymap.set("n", resize_prefix .. "H", "<C-w>h", { remap = true, desc = "Move left" })
  vim.keymap.set("n", resize_prefix .. "J", "<C-w>j", { remap = true, desc = "Move down" })
  vim.keymap.set("n", resize_prefix .. "K", "<C-w>k", { remap = true, desc = "Move up" })
  vim.keymap.set("n", resize_prefix .. "L", "<C-w>l", { remap = true, desc = "Move right" })

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
  vim.keymap.set("n", resize_prefix .. "h", function() resize("h") end, { desc = "Resize left" })
  vim.keymap.set("n", resize_prefix .. "j", function() resize("j") end, { desc = "Resize down" })
  vim.keymap.set("n", resize_prefix .. "k", function() resize("k") end, { desc = "Resize up" })
  vim.keymap.set("n", resize_prefix .. "l", function() resize("l") end, { desc = "Resize right" })
  -- stylua: ignore end

  local gen_clues_resize = function()
    return {
      { mode = "n", keys = resize_prefix .. "q" },
      { mode = "n", keys = resize_prefix .. "H", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "J", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "K", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "L", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "h", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "j", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "k", postkeys = resize_prefix },
      { mode = "n", keys = resize_prefix .. "l", postkeys = resize_prefix },
    }
  end

  MiniClue.setup({
    triggers = {
      { mode = "n", keys = resize_prefix },
      { mode = "n", keys = "[" },
      { mode = "n", keys = "]" },
      { mode = "n", keys = "<C-w>" },
      { mode = "i", keys = "<C-x>" },
      { mode = { "n", "x" }, keys = "<Leader>" },
      { mode = { "n", "x" }, keys = "'" },
      { mode = { "n", "x" }, keys = "`" },
      { mode = { "n", "x" }, keys = '"' },
      { mode = { "n", "x" }, keys = "g" },
      { mode = { "n", "x" }, keys = "z" },
      { mode = { "i", "c" }, keys = "<C-r>" },
    },
    clues = {
      gen_clues_resize(),
      MiniClue.gen_clues.square_brackets(),
      MiniClue.gen_clues.builtin_completion(),
      MiniClue.gen_clues.marks(),
      MiniClue.gen_clues.registers(),
      MiniClue.gen_clues.windows(),
      MiniClue.gen_clues.g(),
      MiniClue.gen_clues.z(),
    },
  })
end)
