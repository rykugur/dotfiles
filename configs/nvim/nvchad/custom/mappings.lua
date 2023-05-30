---@type MappingsTable
local M = {}

-- more keybinds!
M.movement = {
  n = {
    ["h"] = {"<nop>"},
    ["j"] = {"<left>"},
    ["k"] = {"<down>"},
    ["l"] = {"<up>"},
    [";"] = {"<right>"},
  },
  x = {
    ["h"] = {"<nop>"},
    ["j"] = {"<left>"},
    ["k"] = {"<down>"},
    ["l"] = {"<up>"},
    [";"] = {"<right>"},
    ["<leader>t="] = {":Tabularize /=<CR>", "Tabularize on assignment (equals) operator"},
  }
}

return M
