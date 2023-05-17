---@type MappingsTable
local M = {}

-- more keybinds!
M.dusty = {
  n = {
    ["j"] = {"<left>"},
    ["k"] = {"<down>"},
    ["l"] = {"<up>"},
    [";"] = {"<right>"},
  },
  i = {
  },
  v = {
    ["j"] = {"<left>"},
    ["k"] = {"<down>"},
    ["l"] = {"<up>"},
    [";"] = {"<right>"},
    ["<leader>t"] = {"Tabularize /="}
  }
}

return M
