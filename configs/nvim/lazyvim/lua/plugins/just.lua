return {
  { "NoahTheDuke/vim-just" },
  { "IndianBoy42/tree-sitter-just" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "just",
      },
    },
  },
}
