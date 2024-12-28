local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("This plugin requires nvim-telescope/telescope.nvim")
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local terminal = require("aider.terminal")
local config = require("aider").config

local function get_paths(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local paths = {}

	for _, entry in ipairs(picker:get_multi_selection()) do
		local path = entry.path or entry.filename or entry.value
		if path then
			-- Create a file_info-like object
			table.insert(paths, path)
		end
	end

	if #paths == 0 then
		local selection = action_state.get_selected_entry()
		if selection then
			local path = selection.path or selection.filename or selection.value
			if path then
				-- Create a file_info-like object
				table.insert(paths, path)
			end
		end
	end
	actions.close(prompt_bufnr)
	return paths
end

local function aider_add(prompt_bufnr)
	local paths = get_paths(prompt_bufnr)
	terminal.add(paths)
end

local function aider_read_only(prompt_bufnr)
	local paths = get_paths(prompt_bufnr)
	terminal.read_only(paths)
end

local function aider_drop(prompt_bufnr)
	local paths = get_paths(prompt_bufnr)
	terminal.read_only(paths)
end

return telescope.register_extension({
	setup = function()
		if config.telescope_action_key then
			vim.notify(
				"Deprecated: telescope_action_key is deprecated. Use telescope.add instead.",
				vim.log.levels.WARN
			)
			config.telescope.add = config.telescope_action_key
		end
		local files_attach_mappings = function(_, map)
			map("i", config.telescope.add, aider_add)
			map("n", config.telescope.add, aider_add)

			map("i", config.telescope.read_only, aider_read_only)
			map("n", config.telescope.read_only, aider_read_only)

			map("i", config.telescope.drop, aider_drop)
			map("n", config.telescope.drop, aider_drop)
			return true
		end

		-- Override just the file-related pickers
		telescope.setup({
			pickers = {
				find_files = {
					attach_mappings = files_attach_mappings,
				},
				git_files = {
					attach_mappings = files_attach_mappings,
				},
				buffers = {
					attach_mappings = files_attach_mappings,
				},
				oldfiles = {
					attach_mappings = files_attach_mappings,
				},
			},
		})
	end,
})
