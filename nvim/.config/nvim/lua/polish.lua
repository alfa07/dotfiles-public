-- vim.colorscheme = "solarized_light"
-- vim.g.neotree_renderer_icons = {
--   ["toml"] = "",
--   _default = "",
-- }

-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
vim.cmd "set clipboard+=unnamedplus"

vim.keymap.set("n", "<F6>", "<C-i>")
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
map("n", "-", ':lua require("oil").open()<CR>', opts)

if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
-- Set up custom filetypes
vim.filetype.add {
  extension = {
    foo = "fooscript",
  },
  filename = {
    ["Foofile"] = "fooscript",
  },
  pattern = {
    ["~/%.config/foo/.*"] = "fooscript",
  },
}
