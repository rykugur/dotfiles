return {
	{
		"hrsh7th/nvim-cmp",
		opts = {
			sources = {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
				{ name = "lazydev", group_index = 0 },
			},
		},
	},
}
