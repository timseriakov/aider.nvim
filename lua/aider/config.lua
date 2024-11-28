---@class AiderConfig
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string Key to trigger aider load in fzf
---@field aider_args string Additional arguments for aider CLI

local M = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
	editor_command = vim.env.TMUX and "tmux popup -E nvim" or nil,
	fzf_action_key = "ctrl-l",
	aider_args = "",
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
		fzf_config.defaults.files.actions[M.values.fzf_action_key] = require("aider.terminal").load_in_aider
	end
end

return M
