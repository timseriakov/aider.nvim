local M = {}

local themes = {
	"tokyonight",
	"catppuccin",
	"gruvbox",
}

for _, theme in ipairs(themes) do
	local ok, theme_mod = pcall(require, "aider.theme." .. theme)
	if ok then
		M[theme .. "_theme"] = theme_mod[theme .. "_theme"]
	end
end

return M
