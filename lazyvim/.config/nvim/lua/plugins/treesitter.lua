return {
  -- Configure nvim-treesitter with auto-signing for macOS
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })

      -- Auto-sign parsers on macOS after build/update to prevent code signature crashes
      if vim.fn.has("mac") == 1 then
        local parser_path = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser"
        local sign_cmd = string.format(
          "find %s -name '*.so' -exec codesign -s - --force {} \\; 2>/dev/null",
          parser_path
        )
        vim.fn.system(sign_cmd)
        print("✓ Tree-sitter parsers signed for macOS")
      end
    end,
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      -- Automatically install missing parsers when entering buffer
      auto_install = true,
    },
  },
}
