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
		config = function()
			require("window-picker").setup({
				hint = "floating-big-letter",
			})
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		config = function()
			require("neo-tree").setup({
				filesystem = {
					window = {
						mappings = {
							-- revert 'l' key to movement
							["l"] = "noop",
						},
					},
				},
			})
		end,
	},
}
