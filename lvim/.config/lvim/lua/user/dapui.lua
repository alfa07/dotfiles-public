local M = {}

M.config = function()
  local status_ok, dapui = pcall(require, "dapui")
  if not status_ok then
    return
  end

  dapui.setup {
    expand_lines = true,
    icons = {
      expanded = "",
      collapsed = "",
      circular = "",
    },
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.33 },
          { id = "breakpoints", size = 0.17 },
          { id = "stacks", size = 0.25 },
          { id = "watches", size = 0.25 },
        },
        size = 0.31,
        position = "left",
      },
      {
        elements = { { id = "repl", size = 0.45 }, { id = "console", size = 0.55 } },
        size = 0.26,
        position = "bottom",
      },
    },
    floating = { max_width = 0.9, max_height = 0.5, border = vim.g.border_chars },
  }
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return
  end
  dap.listeners.after.event_initialized["dapui_config"] = function()
    vim.cmd [[NvimTreeClose]]
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

return M
