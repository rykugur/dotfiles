return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			filesystem = {
				filtered_items = {
					visible = false,
				},
				update_focused_file = {
					enable = true,
					update_cwd = true,
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
