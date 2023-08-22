return {
	{
		"folke/flash.nvim",
		opts = {
			modes = {
				char = {
					label = {
						exclude = "jkl;iardc",
					},
					keys = { "f", "F", "t", "T" },
				},
			},
		},
	},
	{
		"s1n7ax/nvim-window-picker",
		name = "window-picker",
		event = "VeryLazy",
		version = "2.*",
		opts = {
			hint = "floating-big-letter",
		},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			filesystem = {
				filtered_items = {
					visible = false,
				},
				window = {
					mappings = {
						-- revert 'l' key to movement
						["l"] = "noop",
					},
				},
			},
		},
	},
	{
		"godlygeek/tabular",
	},
	{
		"hrsh7th/nvim-cmp",
		opts = {
			sources = {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
			},
		},
	},
}
