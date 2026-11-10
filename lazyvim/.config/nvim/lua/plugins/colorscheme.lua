-- solarized_light comes from a local plugin checkout at ~/dev/Colorschemes
-- (alfa07/Colorschemes, branch add-solarized-light-color-scheme; DotSync'd on
-- Meta devservers). Where that dir is absent, skip the plugin, so lazy doesn't
-- treat it as missing and rewrite lazy-lock.json on every start, and fall back
-- to a bundled light theme.
local local_colors = vim.fn.expand("~/dev/Colorschemes")
local has_local_colors = vim.fn.isdirectory(local_colors) == 1

return {
  {
    dir = local_colors,
    name = "Colorschemes",
    cond = has_local_colors,
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
      colorscheme = has_local_colors and "solarized_light" or "tokyonight-day",
    },
  },
}
