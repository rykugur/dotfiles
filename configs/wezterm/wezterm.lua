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
}

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font_with_fallback({
	"EnvyCodeR Nerd Font Mono",
	"FiraCode Nerd Font Mono",
	"Iosevka Nerd Font",
	"feather",
})
config.font_size = 12.0

config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 2,
}

config.color_scheme = "Catppuccin Mocha"

config.window_background_opacity = 0.8

-- and finally, return the configuration to wezterm
return config
