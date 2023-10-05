return {
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
}
