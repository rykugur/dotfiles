return {
	"nvim-neorg/neorg",
	cond = function()
		return string.find(vim.fn.getcwd(), "neorg_notes")
	end,
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
						gaming = "~/gits/neorg_notes/gaming",
						linux = "~/gits/neorg_notes/linux",
						misc = "~/gits/neorg_notes/misc",
					},
					default_workspace = "notes",
				},
			},
		},
	},
}
