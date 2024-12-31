local disabled = os.getenv("DISABLE_CODING_ASSISTANT") == "true"

if disabled then
  return {}
end

return {
  "olimorris/codecompanion.nvim",
  keys = {
    { "<leader>aia", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions" },
    { "<leader>aic", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanion Chat" },
    { "<leader>aip", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion Prompt" },
  },
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      sources = {
        default = { "codecompanion" },
        providers = {
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
            enabled = true,
          },
        },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = true,
}
