local pack = require("util.pack")

pack.later(function()
  local MiniDiff = require("mini.diff")

  MiniDiff.setup({
    mappings = {
      textobject = "ih",
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
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>go", function() MiniDiff.toggle_overlay() end, { desc = "Toggle overlay" })

  vim.api.nvim_create_user_command("GitBlame", function()
    local list_wins = vim.api.nvim_list_wins()
    local git_wins = vim
      .iter(list_wins)
      :filter(function(win)
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.bo[buf].ft == "git"
      end)
      :totable()
    if vim.tbl_isempty(git_wins) then
      vim.cmd([[vert above Git blame -- %]])
    else
      for _, win in ipairs(git_wins) do
        vim.api.nvim_win_close(win, false)
      end
    end
  end, {})
  vim.keymap.set("n", "<Leader>gb", "<Cmd>GitBlame<Enter>", { desc = "Toggle blame" })
end)
