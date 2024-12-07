local M = {}

---Setup aider plugin
---@param opts table|nil Configuration options
function M.setup(opts)
	-- Ensure toggleterm is available
	local has_toggleterm, _ = pcall(require, "toggleterm")
	if not has_toggleterm then
		error("This plugin requires akinsho/toggleterm.nvim")
	end

	require("aider.config").setup(opts)
	require("aider.commands").setup()
end

return M
