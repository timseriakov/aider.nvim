local M = {}

---@type tokyonight.HighlightsFn
local function set_tokyonight_theme(c, _)
	return {
		user_input_color = c.git.add,
		tool_output_color = c.blue,
		tool_error_color = c.red1,
		tool_warning_color = c.orange,
		assistant_output_color = c.purple,
		completion_menu_color = c.fg_float,
		completion_menu_bg_color = c.bg_float,
		completion_menu_current_color = c.fg_dark,
		completion_menu_current_bg_color = c.bg_highlight,
	}
end

---@param c table
local function set_catppuccin_colors(c)
	return {
		user_input_color = c.green,
		tool_output_color = c.blue,
		tool_error_color = c.red,
		tool_warning_color = c.yellow,
		assistant_output_color = c.mauve,
		completion_menu_color = c.text,
		completion_menu_bg_color = c.base,
		completion_menu_current_color = c.crust,
		completion_menu_current_bg_color = c.pink,
	}
end

function M.tokyonight_theme()
	if not vim.startswith(vim.g.colors_name, "tokyonight") then
		return -- Do nothing if tokyonight is not active
	end
	local ok, tokyonight_config = pcall(require, "tokyonight.config")
	if not ok then
		return -- Do nothing if tokyonight.config is not found
	end
	local opts = tokyonight_config.options
	local ok, tokyonight_colors = pcall(require, "tokyonight.colors")
	if not ok then
		return -- Do nothing if tokyonight.colors is not found
	end
	return set_tokyonight_theme(tokyonight_colors.setup(opts), opts)
end

function M.catppuccin_theme()
	local ok, _ = pcall(require, "catppuccin.palettes")
	if not ok then
		return
	end

	local current_color = vim.g.colors_name
	local flavour = require("catppuccin").flavour or vim.g.catppuccin_flavour

	if current_color and current_color:match("^catppuccin") and flavour then
		local colors = require("catppuccin.palettes").get_palette()
		return set_catppuccin_colors(colors)
	end
end

function M.gruvbox_theme()
	local ok, gruvbox = pcall(require, "gruvbox")
	if not ok then
		return
	end

	local p = gruvbox.palette

	local color_groups = {
		dark = {
			bg1 = p.dark1,
			bg4 = p.dark4,
			fg1 = p.light1,
			fg4 = p.light4,
			red = p.bright_red,
			green = p.bright_green,
			yellow = p.bright_yellow,
			blue = p.bright_blue,
			purple = p.bright_purple,
			orange = p.bright_orange,
			code_theme = "gruvbox-dark",
		},
		light = {
			bg1 = p.light1,
			bg4 = p.light4,
			fg1 = p.dark1,
			fg4 = p.dark4,
			red = p.faded_red,
			green = p.faded_green,
			yellow = p.faded_yellow,
			blue = p.faded_blue,
			purple = p.faded_purple,
			orange = p.faded_orange,
			code_theme = "gruvbox-light",
		},
	}
	local colors = color_groups[vim.o.background or "dark"]

	return {
		user_input_color = colors.green,
		tool_output_color = colors.blue,
		tool_error_color = colors.red,
		tool_warning_color = colors.orange,
		assistant_output_color = colors.purple,
		completion_menu_color = colors.fg1,
		completion_menu_bg_color = colors.bg1,
		completion_menu_current_color = colors.fg4,
		completion_menu_current_bg_color = colors.bg4,
		code_theme = colors.code_theme,
	}
end

return M
