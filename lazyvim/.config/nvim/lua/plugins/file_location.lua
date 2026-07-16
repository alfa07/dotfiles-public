return {
  "diegoulloao/nvim-file-location",
  event = "VeryLazy",
  config = function()
    require("nvim-file-location").setup({
      keymap = "<leader>F", -- Set the key binding to <leader>cl
      mode = "workdir", -- Options: workdir | absolute
      add_line = true, -- Include line number in the copied text
      add_column = false, -- Don't include column number
      default_register = "+", -- Use the system clipboard register
    })
  end,
}
