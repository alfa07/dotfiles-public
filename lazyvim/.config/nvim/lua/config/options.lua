-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt

-- vim.opt.langmap = table.concat({
--   "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ",
--   "фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz",
-- }, ",")

vim.opt.keymap = "russian-jcukenwin"
vim.opt.iminsert = 0
vim.opt.imsearch = 0

opt.clipboard = "unnamedplus"

if vim.fn.has("unix") == 1 then
  if vim.fn.executable("xclip") == 1 then
    vim.g.clipboard = {
      name = "xclip",
      copy = {
        ["+"] = "xclip -quiet -i -sel clip",
        ["*"] = "xclip -quiet -i -sel prim",
      },
      paste = {
        ["+"] = "xclip -o -sel clip",
        ["*"] = "xclip -o -sel prim",
      },
      cache_enabled = 1,
    }
  elseif vim.fn.executable("xsel") == 1 then
    vim.g.clipboard = {
      name = "xsel",
      copy = {
        ["+"] = "xsel --nodetach -i -b",
        ["*"] = "xsel --nodetach -i -p",
      },
      paste = {
        ["+"] = "xsel -o -b",
        ["*"] = "xsel -o -p",
      },
      cache_enabled = 1,
    }
  elseif vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
    vim.g.clipboard = {
      name = "wl-clipboard",
      copy = {
        ["+"] = "wl-copy --type text/plain",
        ["*"] = "wl-copy --primary --type text/plain",
      },
      paste = {
        ["+"] = "wl-paste --no-newline",
        ["*"] = "wl-paste --primary --no-newline",
      },
      cache_enabled = 1,
    }
  end
elseif vim.fn.has("mac") == 1 then
  vim.g.clipboard = {
    name = "pbcopy",
    copy = {
      ["+"] = "pbcopy",
      ["*"] = "pbcopy",
    },
    paste = {
      ["+"] = "pbpaste",
      ["*"] = "pbpaste",
    },
    cache_enabled = 1,
  }
elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 1,
  }
end
