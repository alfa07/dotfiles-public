-- Create an autocommand to set up the Enter key mapping in quickfix windows
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    -- Set up the mapping for Enter key in the quickfix window
    vim.api.nvim_buf_set_keymap(
      0,
      "n",
      "<CR>",
      '<cmd>lua require("user.qf").handle_qf_selection()<CR>',
      { noremap = true, silent = true }
    )
  end,
})
return {}
