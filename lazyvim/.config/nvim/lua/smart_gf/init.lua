local M = {}

function M.smart_gf()
  local cfile = vim.fn.expand("<cfile>")
  local line = vim.api.nvim_get_current_line()
  local pattern = cfile:gsub("([^%w])", "%%%1") -- Escape special characters
  local full_match = line:match(pattern .. ":(%d+)")
  local filename = cfile
  local lineno = nil
  if full_match then
    lineno = full_match
  else
    local file_line_match = line:match("([^%s%(%)%[%]{}\"']+):(%d+)")
    if file_line_match then
      local parts = vim.split(file_line_match, ":", { plain = true })
      if #parts >= 2 and cfile == parts[1] then
        filename = parts[1]
        lineno = parts[2]
      end
    end
  end

  local ui_filetypes = {
    ["neo-tree"] = true,
    ["NvimTree"] = true,
    ["trouble"] = true,
    ["qf"] = true, -- quickfix
    ["help"] = true,
    ["TelescopePrompt"] = true,
    ["TelescopeResults"] = true, -- Telescope results window
    ["dashboard"] = true,
    ["alpha"] = true, -- Alpha dashboard
    ["DiffviewFiles"] = true,
    ["Outline"] = true,
    ["aerial"] = true,
    ["neoterm"] = true,
    ["toggleterm"] = true,
    ["terminal"] = true, -- Terminal buffers can be buftype or filetype
    ["floaterm"] = true,
    ["lazygit"] = true,
    ["oil"] = true, -- Oil.nvim file explorer
    ["minifiles"] = true, -- Mini.files
    ["lir"] = true, -- Lir file explorer
    ["lazy"] = true, -- Lazy plugin manager
    ["mason"] = true, -- Mason package manager
    ["vista"] = true, -- Vista.vim
    ["spectre"] = true, -- Spectre search/replace
    ["netrw"] = true, -- Netrw
    ["fugitive"] = true, -- Fugitive
    ["fugitiveblame"] = true, -- Fugitive blame
    ["startify"] = true, -- Startify
    ["coc-explorer"] = true, -- CoC explorer
    ["lspsagaoutline"] = true, -- Lspsaga outline
    ["lspinfo"] = true, -- LSP info
    ["which-key"] = true, -- Which-key
    ["edgy"] = true, -- Edgy sidebar
    ["noice"] = true, -- Noice UI
    ["dap-repl"] = true, -- DAP REPL
    ["lsp-installer"] = true, -- LSP installer
  }

  -- Dictionary of UI buffer types to ignore
  local ui_buftypes = {
    ["terminal"] = true,
    ["nofile"] = true,
    ["quickfix"] = true,
    ["prompt"] = true,
    ["help"] = true,
  }

  -- Function to check if a window is a special UI window
  local function is_ui_window(win_id)
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    local buf_type = vim.api.nvim_get_option_value("buftype", { buf = buf_id })
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf_id })

    -- Check for DAP UI windows that start with 'dapui_'
    if filetype:match("^dapui_") then
      return true
    end

    -- Check dictionary for UI buftypes
    if ui_buftypes[buf_type] then
      return true
    end

    -- Check dictionary for UI filetypes
    return ui_filetypes[filetype] or false
  end

  -- Check if there's a window above, below, left, or right
  local has_window = false
  local original_win = vim.fn.winnr()
  local target_win = nil

  -- Check window above
  vim.cmd("wincmd k")
  if vim.fn.winnr() ~= original_win then
    local current_win_id = vim.api.nvim_get_current_win()
    if not is_ui_window(current_win_id) then
      has_window = true
      target_win = vim.fn.winnr()
    end
    vim.cmd("wincmd j")
  end

  -- Check window below
  if not has_window then
    vim.cmd("wincmd j")
    if vim.fn.winnr() ~= original_win then
      local current_win_id = vim.api.nvim_get_current_win()
      if not is_ui_window(current_win_id) then
        has_window = true
        target_win = vim.fn.winnr()
      end
      vim.cmd("wincmd k")
    end
  end

  -- Check window left
  if not has_window then
    vim.cmd("wincmd h")
    if vim.fn.winnr() ~= original_win then
      local current_win_id = vim.api.nvim_get_current_win()
      if not is_ui_window(current_win_id) then
        has_window = true
        target_win = vim.fn.winnr()
      end
      vim.cmd("wincmd l")
    end
  end

  -- Check window right
  if not has_window then
    vim.cmd("wincmd l")
    if vim.fn.winnr() ~= original_win then
      local current_win_id = vim.api.nvim_get_current_win()
      if not is_ui_window(current_win_id) then
        has_window = true
        target_win = vim.fn.winnr()
      end
      vim.cmd("wincmd h")
    end
  end

  -- If there's an existing window, move to it and open the file
  if has_window then
    vim.cmd(target_win .. "wincmd w")
  else
    -- Otherwise create a new split and open the file
    vim.cmd("wincmd v")
  end
  print(filename, lineno)
  vim.cmd("edit " .. filename)
  if lineno then
    vim.cmd(lineno)
  end
end

-- Setup function to create mappings
function M.setup()
  vim.keymap.set("n", "gF", function()
    require("smart_gf").smart_gf()
  end, {
    noremap = true,
    silent = true,
  })
end
return M
