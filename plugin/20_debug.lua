local pack = require("util.pack")

pack.add({
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/igorlfs/nvim-dap-view" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
})

pack.later(function()
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
  --
  dap.listeners.before.attach.dapui_config = function() dap.view.open() end
  dap.listeners.before.launch.dapui_config = function() dap.view.open() end
  dap.listeners.before.event_terminated.dapui_config = function() dap_view.close() end
  dap.listeners.before.event_exited.dapui_config = function() dap_view.close() end
  -- stylua: ignore end

  -- Go

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
end)
