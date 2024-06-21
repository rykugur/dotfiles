-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.keys = {
	{
		key = "-",
		mods = "CTRL|SUPER",
		action = wezterm.action.Nop,
	},
	{
		key = "=",
		mods = "CTRL|SUPER",
		action = wezterm.action.Nop,
	},
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.Nop,
	},
}

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font_with_fallback({
	"FiraCode Nerd Font Mono",
	"EnvyCodeR Nerd Font Mono",
	"feather",
})
config.font_size = 12.0

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.color_scheme = "Catppuccin Mocha"

config.window_background_opacity = 0.8

-- and finally, return the configuration to wezterm
return config
