return {
	{
		{
			"folke/lazydev.nvim",
			ft = "lua",
			cmd = "LazyDev",
			opts = {
				library = {
					{ path = "luvit-meta/library", words = { "vim%.uv" } },
					{ path = "LazyVim", words = { "LazyVim" } },
					{ path = "lazy.nvim", words = { "LazyVim" } },
				},
			},
		},
	},
}
