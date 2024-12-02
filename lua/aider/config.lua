---@class AiderConfig
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string Key to trigger aider load in fzf
---@field aider_args string Additional arguments for aider CLI
---@field toggleterm table Toggleterm configuration
---@field toggleterm.direction string Window layout type ('float'|'vertical'|'horizontal')
---@field toggleterm.size function Size function for terminal

local M = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
    editor_command = nil,
    fzf_action_key = "ctrl-l",
    telescope_action_key = "<C-l>",
    aider_args = "",
    toggleterm = {
        direction = "vertical",
        size = function(term)
            if term.direction == "horizontal" then
                return math.floor(vim.o.lines * 0.4)
            elseif term.direction == "vertical" then
                return math.floor(vim.o.columns * 0.4)
            end
        end,
    }
}

---Current configuration
---@type AiderConfig
M.values = {}

---Initialize configuration with user options
---@param opts AiderConfig|nil User configuration options
function M.setup(opts)
	opts = opts or {}
	M.values = vim.tbl_deep_extend("force", {}, M.defaults, opts)

	if M.editor_command == nil then
		vim.env.AIDER_EDITOR = "nvim --cmd 'let g:flatten_wait=1' --cmd 'cnoremap wq write<bar>bdelete<bar>startinsert'"
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
