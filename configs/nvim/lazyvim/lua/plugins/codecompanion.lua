local disabled = os.getenv("DISABLE_CODING_ASSISTANT") == "true"

if disabled then
  return {}
end

return {
  {
    "olimorris/codecompanion.nvim",
    keys = {
      { "<leader>aia", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions" },
      { "<leader>aic", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanion Chat" },
      { "<leader>aip", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion Prompt" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      --"github/copilot.nvim",
    },
    config = true,
    -- opts = {
    --   strategies = {
    --     chat = {
    --       adapter = "copilot",
    --     },
    --     inline = {
    --       adapter = "copilot",
    --     },
    --   },
    --   adapters = {
    --     xai = function()
    --       return require("codecompanion.adapters").extend("xai", {
    --         env = {
    --           api_key = 'cmd:op read "op://Private/u6zvafdqw6oyrn536eqqbr7zsq/codecompanion api key"',
    --         },
    --       })
    --     end,
    --   },
    -- },
  },
  -- {
  --   "saghen/blink.cmp",
  --   ---@module 'blink.cmp'
  --   ---@type blink.cmp.Config
  --   opts = {
  --     sources = {
  --       -- default = { "codecompanion" },
  --       default = { "lsp", "path", "snippets", "buffer", "codecompanion" },
  --       -- providers = {
  --       --   codecompanion = {
  --       --     name = "CodeCompanion",
  --       --     module = "codecompanion.providers.completion.blink",
  --       --     enabled = true,
  --       --   },
  --       -- },
  --     },
  --   },
  -- },
}
