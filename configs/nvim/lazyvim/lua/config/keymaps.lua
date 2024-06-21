-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
	vim.keymap.set(mode, lhs, rhs, opts)
end

map({ "n", "x" }, "h", "<nop>")
map({ "n", "x" }, "j", "<left>")
map({ "n", "x" }, "k", "<down>")
map({ "n", "x" }, "l", "<up>")
map({ "n", "x" }, ";", "<right>")

map("n", "<C-w>h", "<nop>")
map("n", "<C-w>j", "<nop>")
map("n", "<C-w>k", "<nop>")
map("n", "<C-w>l", "<nop>")
map("n", "<C-j>", "<C-w>h", { desc = "move cursor to window left", noremap = true })
map("n", "<C-k>", "<C-w>j", { desc = "move cursor to window down", noremap = true })
map("n", "<C-l>", "<C-w>k", { desc = "move cursor to window up", noremap = true })
map("n", "<C-;>", "<C-w>l", { desc = "move cursor to window right", noremap = true })

map("x", "<leader>t=", ":Tabularize /=<CR>", { desc = "Tabularize on =" })

map({ "n", "x" }, "<C-/>", "<nop>")
