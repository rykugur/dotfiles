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
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = {
  --     servers = {
  --       lua_ls = {
  --         workspace = {
  --           checkThirdParty = true,
  --           library = {
  --             "${3rd}/love2d/library",
  --             -- "~/.luarocks/share/lua/5.1/?.lua",
  --             -- "~/.luarocks/share/lua/5.1/?/init.lua",
  --             -- vim.fn.expand("~/.luarocks/share/lua/5.1/?.lua"),
  --             -- vim.fn.expand("~/.luarocks/share/lua/5.1/?/init.lua"),
  --           },
  --         },
  --       },
  --     },
  --   },
  -- },
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
  -- {
  --   "nvim-neotest/neotest",
  --   dependencies = {
  --     "haydenmeade/neotest-jest",
  --     "marilari88/neotest-vitest",
  --   },
  --   keys = {
  --     {
  --       "<leader>tl",
  --       function()
  --         require("neotest").run.run_last()
  --       end,
  --       desc = "Run Last Test",
  --     },
  --     {
  --       "<leader>tL",
  --       function()
  --         require("neotest").run.run_last({ strategy = "dap" })
  --       end,
  --       desc = "Debug Last Test",
  --     },
  --     {
  --       "<leader>tw",
  --       "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
  --       desc = "Run Watch",
  --     },
  --   },
  --   opts = function(_, opts)
  --     table.insert(
  --       opts.adapters,
  --       require("neotest-jest")({
  --         jestCommand = "yarn jest --",
  --         jestConfigFile = "custom.jest.config.ts",
  --         env = { CI = true },
  --         cwd = function()
  --           return vim.fn.getcwd()
  --         end,
  --       })
  --     )
  --     table.insert(opts.adapters, require("neotest-vitest"))
  --   end,
  -- },
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
