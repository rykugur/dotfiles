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
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "fish",
        "http",
        "json",
        "lua",
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
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
      },
      formatters = {
        prettier = {
          require_cwd = true,
          -- cwd = require("conform.util").root_file({
          --   ".prettierrc",
          --   ".prettierrc.json",
          --   ".prettierrc.yml",
          --   ".prettierrc.yaml",
          --   ".prettierrc.json5",
          --   ".prettierrc.js",
          --   ".prettierrc.cjs",
          --   ".prettierrc.mjs",
          --   ".prettierrc.toml",
          --   "prettier.config.js",
          --   "prettier.config.cjs",
          --   "prettier.config.mjs",
          -- }),
        },
      },
    },
  },
}
