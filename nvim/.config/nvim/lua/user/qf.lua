local M = {}

-- Function to handle quickfix item selection
M.handle_qf_selection = function()
  -- Get the line number of the selected quickfix item
  local line_nr = vim.fn.line "."

  -- Get the quickfix item
  local qf_item = vim.fn.getqflist()[line_nr]

  -- Go to the previous window (the one that was active before quickfix)
  vim.cmd "wincmd p"

  -- Jump to the location
  vim.api.nvim_win_set_buf(0, vim.fn.bufnr(qf_item.bufnr))
  vim.api.nvim_win_set_cursor(0, { qf_item.lnum, qf_item.col - 1 })

  -- Close the quickfix window
  vim.cmd "cclose"
end

return M
