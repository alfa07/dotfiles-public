-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "solarized_light"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

lvim.builtin.telescope.defaults.path_display = { "truncate" }
lvim.builtin.telescope.pickers.buffers.initial_mode = "insert"
-- vim.opt.listchars = { tab = '▷', trail = '·', extends = '◣', precedes = '◢', nbsp = '○' }
vim.opt.listchars = { space = '_', tab = '>~' }

-- Fixing potential slow down due to excessive getattrlist calls
-- Suspect due to inspection of `sudo fs_use`
lvim.builtin.project.active = true
lvim.builtin.project.patterns = { ".git", "Cargo.lock", "package.json" }


lvim.builtin.which_key.mappings["<leader>"] = { "<cmd>Telescope buffers<CR>", "Buffers" }
lvim.builtin.which_key.mappings["r"] = { "<cmd>lua require('spectre').open()<CR>", "Replace In Project" }
lvim.builtin.which_key.mappings["k"] = { "<Cmd>lua require('telescope').extensions.frecency.frecency()<CR>",
  "Find File" }
lvim.builtin.which_key.mappings["j"] = { "<Cmd>lua require('telescope.builtin').grep_string()<CR>", "Find String" }
lvim.builtin.which_key.mappings["d"] = {
  name = "+Diff View",
  o = { "<cmd>DiffviewOpen<CR>", "Open" },
  c = { "<cmd>DiffviewClose<CR>", "Close" },
  h = { "<cmd>DiffviewFileHistory %<CR>", "View File History" },
}
lvim.builtin.which_key.mappings["o"] = { "<Cmd>Neotree buffers reveal right<CR>", "Show open buffers" }

lvim.builtin.telescope.defaults.layout_config.width = 0.99
lvim.builtin.telescope.defaults.layout_config.preview_cutoff = 120

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
-- lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
-- lvim.builtin.terminal.open_mapping = [[<c-=>]]
lvim.builtin.terminal.open_mapping = "<c-t>"
lvim.builtin.terminal.direction = "horizontal"
lvim.builtin.terminal.insert_mappings = false
lvim.builtin.terminal.shading_factor = 0

lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
-- lvim.builtin.nvimtree.setup.git.enable = false
lvim.builtin.nvimtree.setup.git.timeout = 150
lvim.builtin.nvimtree.setup["filesystem_watchers"] = {
  enable = true,
  -- Else fseventsd goes into a tailspin
  ignore_dirs = {
    "\\.cargo$",
    "/target$",
    "\\.git$",
  },
}
-- lvim.builtin.nvimtree.setup["modified"] = { enable = false }
lvim.builtin.indentlines.options["char_highlight_list"] = {
  "IndentBlanklineIndent1",
  "IndentBlanklineIndent2",
  "IndentBlanklineIndent3",
  "IndentBlanklineIndent4",
  "IndentBlanklineIndent5",
  "IndentBlanklineIndent6",
}

lvim.builtin.dap.active = true

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "go",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers,
  { "rust_analyzer", "gopls" })
local opts = {
  settings = {
    ["rust-analyzer"] = {
      rustfmt = { extraArgs = { "+nightly" } }
    }
  }
}
require("lvim.lsp.manager").setup("rust_analyzer", opts)
-- require("lvim.lsp.manager").setup("astro", {})
require("lspconfig").astro.setup {
  init_options = {
    typescript = {
      tsdk = 'node_modules/typescript/lib'
    }
  }
}

-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  { command = "isort", filetypes = { "python" } },
  {
    command = "shfmt",
    filetypes = { "sh", "bash" },
  },
}

vim.cmd [[
    let g:tmuxjump_telescope = v:true
    let g:bclose_no_plugin_maps = v:true
]]

-- require "maxim.globals"

lvim.builtin.telescope.on_config_done = function(telescope)
  pcall(telescope.load_extension, "frecency")
  -- pcall(telescope.load_extension, "neoclip")
  -- any other extensions loading
end

-- Additional Plugins
lvim.plugins = {
  { "tpope/vim-surround" },
  { "tpope/vim-abolish" },
  { "tpope/vim-eunuch" },
  { "tpope/vim-repeat" },
  { "tpope/vim-sleuth" },
  { "christoomey/vim-tmux-navigator" },
  { 'shivamashtikar/tmuxjump.vim' },
  { 'jremmen/vim-ripgrep' },
  {
    'windwp/nvim-spectre',
    event = "BufRead",
    config = function()
      require("spectre").setup()
    end,
  },
  -- libuv docs
  { 'nanotee/luv-vimdocs' },
  { 'milisims/nvim-luaref' },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
      { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,     desc = "Remote Flash" },
      {
        "R",
        mode = { "o", "x" },
        function() require("flash").treesitter_search() end,
        desc =
        "Treesitter Search"
      },
      {
        "<c-s>",
        mode = { "c" },
        function() require("flash").toggle() end,
        desc =
        "Toggle Flash Search"
      },
    },
  },
  -- telescope extension
  {
    "nvim-telescope/telescope-frecency.nvim",
    -- config = function()
    --   require "telescope".load_extension("frecency")
    -- end,
    dependencies = { "tami5/sqlite.lua" },
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require 'colorizer'.setup()
    end,
  },
  -- {
  --   'maxmx03/solarized.nvim',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.o.background = 'light' -- or 'dark'
  --     vim.cmd.colorscheme 'solarized'
  --   end,
  -- },
  {
    dir = "~/dev/Colorschemes",
    config = function()
      vim.o.background = 'light' -- or 'dark'
    end,
  },
  {
    dir = "~/ai/aicomplete",
    config = function()
    end,
  },
  {
    "nvim-treesitter/playground",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require "nvim-treesitter.configs".setup {
        playground = {
          enable = true,
          disable = {},
          updatetime = 25,         -- Debounced time for highlighting nodes in the playground from source code
          persist_queries = false, -- Whether the query persists across vim sessions
          keybindings = {
            toggle_query_editor = 'o',
            toggle_hl_groups = 'i',
            toggle_injected_languages = 't',
            toggle_anonymous_nodes = 'a',
            toggle_language_display = 'I',
            focus_language = 'f',
            unfocus_language = 'F',
            update = 'R',
            goto_node = '<cr>',
            show_help = '?',
          },
        }
      }
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    }
  },
  {
    'wellle/targets.vim',
  },
  { 'preservim/tagbar' },
  { 'voldikss/vim-floaterm' },
  { 'ruanyl/vim-gh-line' },
  -- {
  --   'pwntester/octo.nvim',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'nvim-telescope/telescope.nvim',
  --     'nvim-tree/nvim-web-devicons',
  --   },
  --   config = function()
  --     require "octo".setup()
  --   end
  -- },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
  },
  {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },
  {
    "LhKipp/nvim-nu",
    build = function()
      vim.cmd([[TSInstall nu]])
    end,
  },
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     local model = "gpt-4-1106-preview"
  --     local config = {
  --       openai_params = {
  --         model = model,
  --         frequency_penalty = 0,
  --         presence_penalty = 0,
  --         max_tokens = 32000,
  --         temperature = 0,
  --         top_p = 1,
  --         n = 1,
  --       },
  --       openai_edit_params = {
  --         model = model,
  --         frequency_penalty = 0,
  --         presence_penalty = 0,
  --         temperature = 0,
  --         top_p = 1,
  --         n = 1,
  --       },
  --       use_openai_functions_for_edits = false,
  --     }
  --     require("chatgpt").setup(config)
  --   end,
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim"
  --   }
  -- },
  {
    'IndianBoy42/tree-sitter-just',
    config = function()
      local config = {}
      require("tree-sitter-just").setup(config)
    end
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-tree/nvim-tree.lua",
      "kyazdani42/nvim-tree.lua",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.ai').setup()
      require('mini.operators').setup()
      require('mini.trailspace').setup()
    end
  },
  {
    'ntpeters/vim-better-whitespace',
    config = function()
      vim.cmd([[
        highlight ExtraWhitespace ctermbg=Red
        let g:better_whitespace_enabled=1
        " autocmd FileType <desired_filetypes> EnableStripWhitespaceOnSave
        " let g:strip_whitespace_on_save=1
      ]])
    end
  },
  {
    'stevearc/aerial.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      -- Aerial
      require("aerial").setup({
        -- optionally use on_attach to set keymaps when aerial has attached to a buffer
        on_attach = function(bufnr)
          -- Jump forwards/backwards with '{' and '}'
          vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
          vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
        end,
      })
      -- You probably also want to set a keymap to toggle aerial
      vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
    end
  },
}


vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])


-- Copilot setup
-- lvim.builtin.cmp.formatting.source_names["copilot"] = "(Copilot)"
-- table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })
-- vim.keymap.set('i', '<M-CR>', '<Plug>(copilot)')
-- vim.keymap.set('n', '<M-CR>', '<Plug>(copilot)')
-- vim.keymap.set('i', '<M-.>', '<Plug>(copilot-next)')
-- vim.keymap.set('i', '<M-,>', '<Plug>(copilot-previous)')

local ok, copilot = pcall(require, "copilot")
if not ok then
  return
end

copilot.setup {
  suggestion = {
    keymap = {
      accept = "<c-l>",
      next = "<c-j>",
      prev = "<c-k>",
      dismiss = "<c-h>",
    },
  },
}

opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<c-f>", "<cmd>lua require('copilot.suggestion').toggle_auto_trigger()<CR>", opts)

if lvim.builtin.dap.active then
  require("user.dap").config()
end
vim.cmd [[
nmap <F8> :TagbarToggle<CR>
]]
vim.on_key(function(char)
  if vim.fn.mode() == "n" then
    vim.opt.hlsearch = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
  end
end, vim.api.nvim_create_namespace "auto_hlsearch")
vim.cmd [[
noremap <C-b> :FloatermNew --opener=edit --height=1.0 --width=1.0 broot<CR>
]]

-- close quickfix menu after selecting choice
vim.api.nvim_create_autocmd(
  "FileType", {
    pattern = { "qf" },
    command = [[nnoremap <buffer> <CR> <CR>:cclose<CR>]]
  })

-- vim.cmd [[
--   " Highlight trailing spaces
--   match ErrorMsg '\s\+$'

--   " Highlight missing newline at the end of file
--   autocmd BufRead,BufNewFile * if getline('$') !~ '\n$' | match ErrorMsg '\%$\@<!.\+' | endif
-- ]]

-- Terraform
--
lvim.builtin.terraform = {
  active = true,
  on_config_done = nil,
  options = {
    server = {
      enabled = true,
      cmd = { "terraform-ls", "serve" },
      on_attach = require("lvim.lsp").common_on_attach,
    },
  },
}

-- Terraform file detection
vim.cmd([[
  autocmd BufNewFile,BufRead *.tf set filetype=terraform
  autocmd BufNewFile,BufRead *.tfvars set filetype=terraform
]])

require('maxim.global')
