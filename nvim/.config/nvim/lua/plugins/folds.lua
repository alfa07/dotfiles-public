require('user.folds')
vim.api.nvim_set_keymap('n', '<CR>', ':lua require("user.folds").toggle_fold()<CR>', { noremap = true, silent = true })
return {}
