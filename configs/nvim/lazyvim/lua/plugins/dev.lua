return {
  { "justinsgithub/wezterm-types", lazy = true },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        { path = "LazyVim", words = { "LazyVim" } },
        { path = "wezterm-types", mods = { "wezterm" } },
      },
    },
  },
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
  { "mfussenegger/nvim-dap", opts = { manual_mode = false }, dependencies = { "rcarriga/nvim-dap-ui" } },
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
