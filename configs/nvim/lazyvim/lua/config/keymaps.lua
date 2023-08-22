-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
	vim.keymap.set(mode, lhs, rhs, opts)
end

map({ "n", "x" }, "h", "<nop>")

map({ "n", "x" }, "h", "<nop>")
map({ "n", "x" }, "j", "<left>")
map({ "n", "x" }, "k", "<down>")
map({ "n", "x" }, "l", "<up>")
map({ "n", "x" }, ";", "<right>")

map("n", "<C-j>", "<C-w>h", { desc = "move cursor to window left" })
map("n", "<C-k>", "<C-w>j", { desc = "move cursor window below" })
map("n", "<C-l>", "<C-w>k", { desc = "move cursor window above" })
map("n", "<C-;>", "<C-w>l", { desc = "move cursor window right" })
map("n", "<leader>wj", "<C-w>h", { desc = "move cursor to window left" })
map("n", "<leader>wk", "<C-w>j", { desc = "move cursor to window left" })
map("n", "<leader>wl", "<C-w>k", { desc = "move cursor to window left" })
map("n", "<leader>w;", "<C-w>l", { desc = "move cursor to window left" })

map("n", "<leader>bj", ":bprevious<CR>", { desc = "move to next buffer" })
map("n", "<leader>b;", ":bnext<CR>", { desc = "move to previous buffer" })

map("x", "<leader>t=", ":Tabularize /=<CR>", { desc = "Tabularize on =" })
