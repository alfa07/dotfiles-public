---@type LazySpec
return {
  {
    'voldikss/vim-floaterm',
    config = function()
      vim.cmd [[
      noremap <C-b> :FloatermNew --opener=edit --height=1.0 --width=1.0 broot<CR>
      ]]
    end,
  },
}
