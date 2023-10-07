return {
	{
		"nvim-lualine/lualine.nvim",
		opts = function()
			return {
				options = {
					theme = "auto",
					component_separators = { left = " ", right = " " },
					section_separators = { left = "", right = "" },
				},
				-- uncomment for bubbles
				-- sections = {
				-- 	lualine_a = {
				-- 		{ "mode", separator = { left = "" }, right_padding = 2 },
				-- 	},
				-- 	lualine_z = {
				-- 		{ "location", separator = { right = "" }, left_padding = 2 },
				-- 	},
				-- },
			}
		end,
	},
}
