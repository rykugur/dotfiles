return {
  {
    "polarmutex/git-worktree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      config = function()
        local Hooks = require("git-worktree.hooks")
        Hooks.register(Hooks.type.SWITCH, Hooks.builtins.update_current_buffer_on_switch)

        LazyVim.on_load("git-worktree.nvim", function()
          require("telescope").load_extension("git_worktree")
        end)
      end,
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>gwl",
        function()
          require("telescope").extensions.git_worktree.git_worktree()
        end,
        desc = "Switch worktrees",
      },
      {
        "<leader>gwc",
        function()
          require("telescope").extensions.git_worktree.create_git_worktree()
        end,
        desc = "Create a worktree",
      },
    },
  },
}
