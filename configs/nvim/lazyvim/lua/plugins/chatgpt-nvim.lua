return {
	"jackMort/ChatGPT.nvim",
	enabled = false,
	event = "VeryLazy",
	config = function()
		require("chatgpt").setup({
			-- api_key_cmd = "op item get OpenAI --fields label='Api Key' --no-newline",
			-- api_key_cmd = "op read op://private/OpenAI/Api Key --no-newline",
		})
	end,
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	keys = {
		{ "<leader>ai", ":ChatGPT<CR>", desc = "Open a chat with ChatGPT" },
	},
}
