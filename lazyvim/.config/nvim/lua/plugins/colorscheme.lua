return {
  {
    dir = "~/dev/Colorschemes",
    config = function()
      vim.colorscheme = "solarized_light"
      vim.o.background = "light" -- or 'dark'
    end,
    lazy = false,
    priority = 1000,
  },
  -- Set your default colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "solarized_light",
    },
  },
}
