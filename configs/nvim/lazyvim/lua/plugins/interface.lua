return {
  -- colorscheme stuff
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        styles = {
          comments = { "italic" },
        },
        integrations = {
          mason = true,
          neotree = true,
          which_key = true,
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    event = "VeryLazy",
    version = "2.*",
    opts = {
      hint = "floating-big-letter",
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "auto",
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        max_name_length = 32,
        tab_size = 32,
      },
    },
    keys = {
      {
        "<leader><tab>H",
        "<cmd>BufferLineMovePrev<CR>",
        desc = "Move current tab to the left",
      },
      {
        "<leader><tab>L",
        "<cmd>BufferLineMoveNext<CR>",
        desc = "Move current tab to the right",
      },
      {
        "<leader><tab>ch",
        "<cmd>BufferLineCloseLeft<CR>",
        desc = "Close all tabs to the left of current",
      },
      {
        "<leader><tab>cl",
        "<cmd>BufferLineCloseRight<CR>",
        desc = "Close all tabs to the right of current",
      },
    },
  },
  {
    "folke/twilight.nvim",
    keys = {
      {
        "<leader>ut",
        function()
          require("twilight").toggle()
        end,
        desc = "Toggle Twiglight",
      },
    },
  },
  {
    "swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    keys = {
      { "<c-h>", "<cmd>ZellijNavigateLeft<cr>", { silent = true, desc = "navigate left or tab" } },
      { "<c-j>", "<cmd>ZellijNavigateDown<cr>", { silent = true, desc = "navigate down" } },
      { "<c-k>", "<cmd>ZellijNavigateUp<cr>", { silent = true, desc = "navigate up" } },
      { "<c-l>", "<cmd>ZellijNavigateRight<cr>", { silent = true, desc = "navigate right or tab" } },
    },
    opts = {},
  },
}
