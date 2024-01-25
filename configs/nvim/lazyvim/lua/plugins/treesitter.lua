return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, {
					"fish",
					"norg",
					"http",
					"json",
					"nix",
					"lua",
				})
			end
		end,
	},
}
