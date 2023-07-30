-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local default_opts = {
	noremap = true,
	silent = true,
}

local keymap = function(mode, lhs, rhs)
	vim.keymap.set(mode, lhs, rhs, default_opts)
end

local n_keymap = function(lhs, rhs)
	keymap("n", lhs, rhs)
end

local x_keymap = function(lhs, rhs)
	keymap("x", lhs, rhs)
end

local nx_keymap = function(lhs, rhs)
	n_keymap(lhs, rhs)
	x_keymap(lhs, rhs)
end

nx_keymap("h", "<nop>")
nx_keymap("j", "<left>")
nx_keymap("k", "<down>")
nx_keymap("l", "<up>")
nx_keymap(";", "<right>")

n_keymap("<C-j>", "<C-w>h")
n_keymap("<C-k>", "<C-w>j")
n_keymap("<C-l>", "<C-w>k")
n_keymap("<C-;>", "<C-w>l")

n_keymap("<S-j>", "<S-w>h")
n_keymap("<S-k>", "<S-w>j")
n_keymap("<S-l>", "<S-w>k")
n_keymap("<S-;>", "<S-w>l")

x_keymap("<leader>t", ":Tabularize /=<CR>")
