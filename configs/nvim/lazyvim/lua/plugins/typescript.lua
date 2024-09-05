-- general catch-all file for javascript/typescript/react
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { { "prettierd", "prettier" } },
        javascriptreact = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        typescriptreact = { { "prettierd", "prettier" } },
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
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "javascript",
        "jsdoc",
      },
    },
  },
  {
    "nvim-neotest/neotest",
    -- adapters = { "neotest-jest" },
    dependencies = {
      "nvim-neotest/neotest-jest",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = function(_, opts)
      table.insert(
        opts.adapters,
        require("neotest-jest")({
          jestCommand = "yarn jest",
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        })
      )
    end,
  },
  {
    "razak17/tailwind-fold.nvim",
    opts = {},
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "html", "svelte", "astro", "vue", "typescriptreact", "php", "blade" },
  },
}
