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
  -- switching to zellij
  -- {
  --   "christoomey/vim-tmux-navigator",
  --   cmd = {
  --     "TmuxNavigateLeft",
  --     "TmuxNavigateDown",
  --     "TmuxNavigateUp",
  --     "TmuxNavigateRight",
  --     "TmuxNavigatePrevious",
  --   },
  --   keys = {
  --     { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
  --     { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
  --     { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
  --     { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
  --     { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
  --   },
  -- },
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
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        file_ignore_patterns = {
          "svg",
          "yarn.lock",
        },
        layout_strategy = "vertical",
        winblend = 0,
      },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    opts = {
      scope = { enabled = true },
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
    "folke/zen-mode.nvim",
    keys = {
      {
        "<leader>uz",
        function()
          require("zen-mode").toggle()
        end,
        desc = "Toggle Zen-mode",
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
