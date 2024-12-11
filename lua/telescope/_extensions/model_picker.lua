local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local aider = require("aider.terminal")
local config = require("aider").config

local function get_models()
	local models = require("telescope._extensions.model_data")
	local filtered_models = {}
	for _, model in ipairs(models) do
		-- Check if model matches any pattern
		for _, match in ipairs(config.model_picker_search) do
			if model:match(match) then
				table.insert(filtered_models, model)
				break
			end
		end
	end
	return filtered_models
end

local model_picker = function(opts)
	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = "Aider Models",
			finder = finders.new_table({
				results = get_models(),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					aider.send_command("/model " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

return require("telescope").register_extension({
	exports = {
		model_picker = model_picker,
	},
})
