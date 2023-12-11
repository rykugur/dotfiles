return {
	"nvim-neorg/neorg",
	event = "VeryLazy",
	opts = {
		load = {
			["core.defaults"] = {},
			["core.concealer"] = {
				config = {
					icon_preset = "diamond",
				},
			},
			["core.dirman"] = {
				config = {
					workspaces = {
						notes = "~/gits/neorg_notes/",
						dev = "~/gits/neorg_notes/dev",
						games = "~/gits/neorg_notes/games",
						linux = "~/gits/neorg_notes/linux",
						misc = "~/gits/neorg_notes/misc",
					},
					default_workspace = "notes",
				},
			},
		},
	},
}
