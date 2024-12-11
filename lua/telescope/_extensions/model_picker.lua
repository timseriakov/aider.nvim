local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local aider = require("aider.terminal")
local config = require("aider").config

local model_cache = nil

local function extract_models(output)
	local models = {}
	for line in output:gmatch("[^\r\n]+") do
		-- Check if line starts with a dash and space
		if line:match("^%- ") then
			-- Remove the dash and space prefix
			local model = line:sub(3)
			table.insert(models, model)
		end
	end
	return models
end

local model_picker = function(opts)
	opts = opts or {}

	if not model_cache then
		-- Create job to run aider --list-models command
		local outputs = {}
		for _, model_search in ipairs(config.model_picker_search) do
			local job = io.popen("aider --no-pretty --list-models " .. '"' .. model_search .. '"')
			if not job then
				vim.notify("Failed to run aider command", vim.log.levels.ERROR)
				return
			end
			-- Read the output
			table.insert(outputs, job:read("*a"))
			job:close()
		end

		-- Extract models from output
		model_cache = extract_models(table.concat(outputs, "\n"))
	end

	pickers
		.new(opts, {
			prompt_title = "Aider Models",
			finder = finders.new_table({
				results = model_cache,
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
