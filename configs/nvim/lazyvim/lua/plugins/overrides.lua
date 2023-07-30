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
					visible = true,
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
}
