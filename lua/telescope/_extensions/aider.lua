local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("This plugin requires nvim-telescope/telescope.nvim")
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local terminal = require("aider.terminal")
local config = require("aider.config")

local function aider_action(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local selections = {}

	for _, entry in ipairs(picker:get_multi_selection()) do
		table.insert(selections, entry.path or entry.value)
	end

	if #selections == 0 then
		local selection = action_state.get_selected_entry()
		if selection then
			table.insert(selections, selection.path or selection.value)
		end
	end

	actions.close(prompt_bufnr)
	terminal.laod_files_in_aider(selections)
end

return telescope.register_extension({
	setup = function()
		telescope.setup({
			defaults = {
				mappings = {
					i = {
						[config.values.telescope_action_key] = aider_action,
					},
					n = {
						[config.values.telescope_action_key] = aider_action,
					},
				},
			},
		})
	end,
})
