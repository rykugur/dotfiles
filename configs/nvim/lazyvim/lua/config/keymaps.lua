-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local default_opts = {
    noremap = true,
    silent = true
}

local keymap = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, default_opts)
    vim.keymap.set('n', ';', '<right>', {
        noremap = true,
        silent = true
    })
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

x_keymap("<leader>t", ":Tabularize /=<CR>")
