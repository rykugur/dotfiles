return {
	{
		"L3MON4D3/LuaSnip",
		init = function()
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { "~/.dotfiles/configs/snippets", "~/.local/snippets" },
			})
		end,
	},
}
