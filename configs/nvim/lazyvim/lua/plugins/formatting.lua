return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			javascript = { "prettierd", "prettier" },
			typescript = { "prettierd", "prettier" },
			nix = { "alejandra" },
		},
	},
}
