local M = {}

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
