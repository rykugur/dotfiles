return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "fish",
        "http",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "markdown",
        "nix",
        "nu",
      },
    },
  },
  { "mistricky/codesnap.nvim", build = "make", opts = { has_breadcrumbs = true } },
  {
    "linrongbin16/gitlinker.nvim",
    cmd = "GitLink",
    opts = {},
    keys = {
      { "<leader>gy", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Yank git link" },
      { "<leader>gY", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open git link" },
    },
  },
  {
    "LintaoAmons/scratch.nvim",
    event = "VeryLazy",
    cmd = { "Scratch", "ScratchWithName", "ScratchOpen", "ScratchOpenFzf" },
    config = function()
      require("scratch").setup({
        filetypes = { "ts", "tsx", "js", "jsx", "sh", "fish" }, -- filetypes to select from
      })
    end,
  },
}
