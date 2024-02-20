return {
	"neovim/nvim-lspconfig",
	opts = {
		servers = {
			tsserver = {
				init_options = {
					preferences = {
						importModuleSpecifierPreference = "non-relative",
					},
				},
			},
		},
	},
}
