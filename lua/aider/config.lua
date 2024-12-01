---@class AiderConfig
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string Key to trigger aider load in fzf
---@field aider_args string Additional arguments for aider CLI
---@field window table Window display configuration
---@field window.layout string Window layout type ('float'|'vertical'|'horizontal'|'current')
---@field window.width number Window width (absolute if >1, percentage if <=1)
---@field window.height number Window height (absolute if >1, percentage if <=1)
---@field window.relative string Position relative to ('editor'|'win'|'cursor')
---@field window.row number Row position for float windows
---@field window.col number Column position for float windows
---@field window.border string|table Border style
---@field window.title string Window title
---@field window.title_pos string Title position
---@field window.opts table Additional window options

local M = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
	editor_command = vim.env.TMUX and "tmux popup -E nvim" or nil,
	fzf_action_key = "ctrl-l",
	telescope_action_key = "<C-l>",
	aider_args = "",
	window = {
		layout = "vertical",
		width = 0.4,
		height = 0.8,
		relative = "editor",
		row = nil,
		col = nil,
		border = "rounded",
		title = "Aider",
		title_pos = "center",
		opts = {
			wrap = true,
			number = false,
			relativenumber = false,
		},
	},
}

---Current configuration
---@type AiderConfig
M.values = {}

---Initialize configuration with user options
---@param opts AiderConfig|nil User configuration options
function M.setup(opts)
	opts = opts or {}
	M.values = vim.tbl_deep_extend("force", {}, M.defaults, opts)
	-- Set AIDER_EDITOR if specified
	if M.values.editor_command then
		vim.env.AIDER_EDITOR = M.values.editor_command
	end
	-- Setup fzf-lua integration if available
	local ok, fzf_config = pcall(require, "fzf-lua.config")
	if ok then
		local load_in_aider = require("aider.terminal").laod_files_in_aider
		fzf_config.defaults.files.actions[M.values.fzf_action_key] = load_in_aider
	end

	-- Setup telescope integration if available
	local telescope_ok, telescope = pcall(require, "telescope")
	if telescope_ok then
		telescope.load_extension("aider")
	end
end

return M
