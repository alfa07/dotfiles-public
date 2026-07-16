local M = {}

M.toggle_fold = function()
  local current_line = vim.fn.line(".")
  local fold_closed = vim.fn.foldclosed(current_line)

  if fold_closed == -1 then
    pcall(function () vim.cmd("normal! zc") end)
  else
    pcall(function () vim.cmd("normal! zo") end)
  end
end

return M
