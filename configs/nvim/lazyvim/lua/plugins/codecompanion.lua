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
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
    "nvim-telescope/telescope.nvim", -- Optional: For using slash commands
    { "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves `vim.ui.select`
    "github/copilot.vim",
  },
  config = true,
}
