---@class ToggletermConfig
---@field direction string Window layout type ('float'|'vertical'|'horizontal'|'tab')
---@field size function Size function for terminal

---@class AiderConfig
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string Key to trigger aider load in fzf
---@field aider_args table Additional arguments for aider CLI
---@field win ToggletermConfig window options
---@field spawn_on_startup boolean|nil
---@field float_opts table<string, any>?
---@field after_update_hook function|nil
---@field notify function
---@field watch_files boolean
---@field confirm_with_vim_ui boolean
---@field telescope_action_key string
---@field auto_insert true
---@field dark_mode function|boolean
---@field model_picker_search table
---@field on_term_open function|nil
---@field restart_on_chdir boolean
---@field auto_scroll boolean
---@field write_to_buffer boolean
---@field theme table

local M = {}

-- Table to store temporary file names
vim.g.aider_temp_files = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
	watch_files = true,
	editor_command = nil,
	fzf_action_key = "ctrl-l",
	model_picker_search = { "^anthropic/", "^openai/", "^gemini/" },
	telescope_action_key = "<C-l>",
	write_to_buffer = true,
	auto_insert = true,
	notify = function(msg, level, opts)
		vim.notify(msg, level, opts)
	end,
	aider_args = {},
	spawn_on_startup = true,
	restart_on_chdir = false,
	on_term_open = function()
		local function tmap(key, val)
			local opt = { buffer = 0 }
			vim.keymap.set("t", key, val, opt)
		end
		-- exit insert mode
		tmap("<Esc>", "<C-\\><C-n>")
		tmap("jj", "<C-\\><C-n>")
		-- enter command mode
		tmap(":", "<C-\\><C-n>:")
		-- scrolling up/down
		tmap("<C-u>", "<C-\\><C-n><C-u>")
		tmap("<C-d>", "<C-\\><C-n><C-d>")
		-- remove line numbers
		vim.wo.number = false
		vim.wo.relativenumber = false
		vim.wo.linebreak = true
	end,
	after_update_hook = nil,
	confirm_with_vim_ui = false,
	dark_mode = function()
		return vim.o.background == "dark"
	end,
	focus_on_spawn = false,
	auto_scroll = false,
	win = {
		direction = "float",
		size = function(term)
			if term.direction == "horizontal" then
				return math.floor(vim.api.nvim_win_get_height(0) * 0.4)
			elseif term.direction == "vertical" then
				return math.floor(vim.api.nvim_win_get_width(0) * 0.4)
			end
		end,
	},
	theme = {
		user_input_color = "#a6da95",
		tool_output_color = "#8aadf4",
		tool_error_color = "#ed8796",
		tool_warning_color = "#eed49f",
		assistant_output_color = "#c6a0f6",
		completion_menu_color = "#cad3f5",
		completion_menu_bg_color = "#24273a",
		completion_menu_current_color = "#181926",
		completion_menu_current_bg_color = "#f4dbd6",
	},
}

---@class AiderConfig
M.config = {}

---@type tokyonight.HighlightsFn
function set_tokyonight_theme(c, opts)
	M.config.theme = {
		user_input_color = c.blue,
		tool_output_color = c.blue,
		tool_error_color = c.red1,
		tool_warning_color = c.yellow,
		assistant_output_color = c.blue,
		completion_menu_color = c.fg_float,
		completion_menu_bg_color = c.bg_float,
		completion_menu_current_color = c.fg_dark,
		completion_menu_current_bg_color = c.bg_highlight,
	}
end

local function setup_tokyonight_integration()
	if not vim.startswith(vim.g.colors_name, "tokyonight") then
		return -- Do nothing if tokyonight is not active
	end

	-- use pcall for these require statements and return early if not found ai!
	local tokyonight_config = require("tokyonight.config")
	local opts = tokyonight_config.options

	local tokyonight_colors = require("tokyonight.colors").setup(opts)

	set_tokyonight_theme(tokyonight_colors, opts)
end

---Initialize configuration with user options
---@param opts AiderConfig|nil User configuration options
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", {}, M.defaults, opts)

	setup_tokyonight_integration()
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
			require("aider.terminal").load_files(cleaned_paths)
		end

		---@type { [string]: function|table }
		local actions = fzf_config.defaults.files.actions
		actions[M.config.fzf_action_key] = fzf_load_in_aider
	end

	-- Setup telescope integration if available
	local telescope_ok, telescope = pcall(require, "telescope")
	if telescope_ok then
		telescope.load_extension("file_pickers")
		telescope.load_extension("model_picker")
	end
	require("aider.commands").setup(M.config)
end

return M
