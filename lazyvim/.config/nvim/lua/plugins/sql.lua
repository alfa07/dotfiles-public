-- return {
--   "stevearc/conform.nvim",
--   -- optional = true,
--   opts = function(_, opts)
--     -- Initialize tables if they don't exist
--     opts.formatters = opts.formatters or {}
--     opts.formatters_by_ft = opts.formatters_by_ft or {}
--
--     -- Define sql file types if not defined earlier
--     local sql_ft = { "sql", "mysql", "plsql" }
--
--     -- Configure sqlfluff formatter
--     opts.formatters.sqlfluff = {
--       args = { "format", "--dialect=ansi", "-" },
--     }
--
--     -- Add sqlfluff to each SQL filetype
--     for _, ft in ipairs(sql_ft) do
--       opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
--       table.insert(opts.formatters_by_ft[ft], "sqlfluff")
--     end
--
--     return opts
--   end,
-- }
return {
  -- SQL Formatter
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "sqlfluff" })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sql = { "sqlfluff" },
      },
      formatters = {
        sqlfluff = {
          command = "sqlfluff",
          args = { "format", "--dialect=ansi", "-" },
        },
      },
    },
  },
}
