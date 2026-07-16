if not vim.fn.isdirectory(vim.fn.expand("~/.opam/default/share/why3/vim")) then
  return {}
end

return {
  {
    dir = "~/.opam/default/share/why3/vim",
    optional = true,
    filetypes = { "mlw" },
  },
  {
    "nvim-mini/mini.comment",
    -- optional = true,
    -- filetypes = { "mlw" },
    opts = {
      options = {
        custom_commentstring = function()
          -- Add MLW files support with OCaml-style comments
          if vim.bo.filetype == "mlw" then
            return "(*%s*)"
          end
          return nil
        end,
      },
    },
  },
}
