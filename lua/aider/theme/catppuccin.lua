local M = {}

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

return M
