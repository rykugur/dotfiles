local disabled = os.getenv("DISABLE_COPILOT") == "true"

return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = not disabled,
  },
  {
    "zbirenbaum/copilot-cmp",
    enabled = not disabled,
  },
  { "zbirenbaum/copilot.lua", enabled = not disabled },
}
