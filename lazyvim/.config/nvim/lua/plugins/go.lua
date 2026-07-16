if vim.fn.executable("ogofmt") ~= 1 then
  return {}
end

return {
  {
    "stevearc/conform.nvim",
    -- optional = true,
    opts = {
      formatters_by_ft = {
        -- go = { "goimports", lsp_format = "last" },
        go = {
          "ogofmt",
        },
      },
      formatters = {
        -- Define custom formatter
        ogofmt = {
          command = "ogofmt",
          args = { "-i", "-w", "$FILENAME" },
          stdin = false,
        },
      },
    },
  },
}
