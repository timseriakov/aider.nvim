local M = {}

---Load selected files into aider
---@param selected table List of selected files
---@param fopts table Fzf options
function M.add(selected, fopts)
	local cleaned_paths = {}
	for _, entry in ipairs(selected) do
		local file_info = require("fzf-lua.path").entry_to_file(entry, fopts)
		table.insert(cleaned_paths, file_info.path)
	end
	require("aider.terminal").load_files(cleaned_paths)
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
		section.actions = section.actions or {}
		section.actions[config.fzf_action_key] = M.add
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
