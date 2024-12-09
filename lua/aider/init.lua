---@class ToggletermConfig
---@field direction string Window layout type ('float'|'vertical'|'horizontal')
---@field size function Size function for terminal

---@class AiderConfig
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string Key to trigger aider load in fzf
---@field aider_args string Additional arguments for aider CLI
---@field toggleterm ToggletermConfig Toggleterm configuration
---@field spawn_on_startup boolean|nil
---@field float_opts table<string, any>?
---@field after_update_hook function|nil
---@field notify function
---@field watch_files boolean

local M = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
	watch_files = true,
	editor_command = nil,
	fzf_action_key = "ctrl-l",
	telescope_action_key = "<C-l>",
	notify = vim.notify,
	aider_args = "",
	spawn_on_startup = true,
	after_update_hook = nil,
	toggleterm = {
		direction = "vertical",
		size = function(term)
			if term.direction == "horizontal" then
				return math.floor(vim.api.nvim_win_get_height(0) * 0.4)
			elseif term.direction == "vertical" then
				return math.floor(vim.api.nvim_win_get_width(0) * 0.4)
			end
		end,
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

	if M.editor_command == nil then
		vim.env.AIDER_EDITOR = "nvim --cmd 'let g:flatten_wait=1' --cmd 'cnoremap wq write<bar>bdelete<bar>startinsert'"
	end

	-- Setup fzf-lua integration if available
	local ok, fzf_config = pcall(require, "fzf-lua.config")
	if ok then
		local fzf_load_in_aider = function(selected, fopts)
			local cleaned_paths = {}
			for _, entry in ipairs(selected) do
				local file_info = entry
				file_info = require("fzf-lua.path").entry_to_file(entry, fopts)
				table.insert(cleaned_paths, file_info.path)
			end
			require("aider.terminal").load_aider(cleaned_paths)
		end

		---@type { [string]: function|table }
		local actions = fzf_config.defaults.files.actions
		actions[M.values.fzf_action_key] = fzf_load_in_aider
	end

	-- Setup telescope integration if available
	local telescope_ok, telescope = pcall(require, "telescope")
	if telescope_ok then
		telescope.load_extension("aider")
	end
	require("aider.commands").setup(M.values)
end

return M
