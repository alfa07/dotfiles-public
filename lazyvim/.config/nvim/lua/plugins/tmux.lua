return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate window left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate window down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate window up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate window right" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate previous" },
    },
  },
}
