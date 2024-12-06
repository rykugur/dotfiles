-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- NOTE: Ensures that when exiting NeoVim, Zellij returns to normal mode
vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "silent !zellij action switch-mode normal",
})
