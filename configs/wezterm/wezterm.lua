-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- config.keys = {
-- 	{
-- 		key = "-",
-- 		mods = "CTRL|SUPER",
-- 		action = wezterm.action.Nop,
-- 	},
-- 	{
-- 		key = "=",
-- 		mods = "CTRL|SUPER",
-- 		action = wezterm.action.Nop,
-- 	},
-- 	{
-- 		key = "v",
-- 		mods = "CTRL",
-- 		action = wezterm.action.Nop,
-- 	},
-- }

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font_with_fallback({
	"ZedMono Nerd Font Mono",
	"FiraCode Nerd Font Mono",
	"EnvyCodeR Nerd Font Mono",
	"feather",
})
config.font_size = 14.0

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.color_scheme = "Catppuccin Mocha"

config.enable_wayland = false

config.window_background_opacity = 0.95

-- config.default_prog = { "nu", "--login" }

config.initial_rows = 40
config.initial_cols = 160

-- and finally, return the configuration to wezterm
return config
