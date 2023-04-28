-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
--config.color_scheme = 'Afterglow'
--config.font = wezterm.font 'ShureTechMono Nerd Font Mono'
config.font = wezterm.font 'TerminessTTF Nerd Font Mono'
config.font = wezterm.font_with_fallback {
  'Iosevka Nerd Font',
  'feather',
}

config.window_padding = {
  left = 8,
  right = 2,
  top = 2,
  bottom = 2,
}


config.color_scheme = 'zenbones_dark'
-- config.color_scheme = 'Afterglow'

config.window_background_opacity = 0.8

-- and finally, return the configuration to wezterm
return config
