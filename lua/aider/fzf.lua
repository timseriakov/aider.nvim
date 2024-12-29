local M = {}

---@param selected table List of selected files
---@param fopts table Fzf options
local function get_paths(selected, fopts)
	local cleaned_paths = {}
	for _, entry in ipairs(selected) do
		local file_info = require("fzf-lua.path").entry_to_file(entry, fopts)
		table.insert(cleaned_paths, file_info.path)
	end
	return cleaned_paths
end

---Load selected files into aider
---@param selected table List of selected files
---@param fopts table Fzf options
function M.add(selected, fopts)
	local cleaned_paths = get_paths(selected, fopts)
	require("aider.terminal").add(cleaned_paths)
end

---Load selected files into aider
---@param selected table List of selected files
---@param fopts table Fzf options
function M.read_only(selected, fopts)
	local cleaned_paths = get_paths(selected, fopts)
	require("aider.terminal").read_only(cleaned_paths)
end

function M.drop(selected, fopts)
	local cleaned_paths = get_paths(selected, fopts)
	require("aider.terminal").drop(cleaned_paths)
end

---Setup fzf-lua integration
---@param config AiderConfig Configuration options
function M.setup(config)
	local ok, fzf_config = pcall(require, "fzf-lua.config")
	if not ok then
		return
	end

	-- Helper to add action to fzf section
	local function add_action_to_section(section)
		if config.fzf_action_key then
			vim.notify("Deprecated: fzf_action_key is deprecated. Use fzf.add instead.", vim.log.levels.WARN)
			config.fzf.add = config.fzf_action_key
		end
		local function map_str(mapping)
			return mapping:gsub("ctrl", "C")
		end
		local header = string.format(
			"Aider: %s: /add, %s: /drop, %s: /read-only",
			map_str(config.fzf.add),
			map_str(config.fzf.drop),
			map_str(config.fzf.read_only)
		)

		if section.header then
			header = header .. " " .. section.header
		end
		section.header = header

		section.actions = section.actions or {}
		section.actions[config.fzf.add] = M.add
		section.actions[config.fzf.read_only] = M.read_only
		section.actions[config.fzf.drop] = M.drop
	end

	-- Setup actions for different fzf sections
	local sections = {
		fzf_config.defaults.files,
		fzf_config.defaults.git.files,
		fzf_config.defaults.oldfiles,
		fzf_config.defaults.buffers,
		fzf_config.defaults.git.status,
	}

	for _, section in ipairs(sections) do
		add_action_to_section(section)
	end
end

return M
