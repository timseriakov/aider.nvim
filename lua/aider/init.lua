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
---@field watch_files boolean
---@field telescope_action_key string
---@field auto_insert true
---@field dark_mode function|boolean
---@field model_picker_search table
---@field on_term_open function|nil
---@field restart_on_chdir boolean
---@field auto_scroll boolean
---@field theme table|nil
---@field code_theme_dark string
---@field code_theme_light string
---@field progress_notifier table|nil
---@field log_notifier boolean

local M = {}

-- Table to store temporary file names
vim.g.aider_temp_files = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
	-- enable the --watch-files flag for Aider
	-- Aider will automatically start when valid comments are created
	watch_files = true,

	-- for snacks progress notifications
	progress_notifier = {
		style = "minimal",
	},
	-- print logs of Aider's output in the right corner, requires fidget.nvim
	log_notifier = true,

	-- code theme to use for markdown blocks when in dark mode
	code_theme_dark = "monokai",
	-- code theme to use for markdown blocks when in light mode
	code_theme_light = "default",

	-- commane to run for opening nested editor when invoking `/editor` from Aider terminal
	-- requires flatten.nvim to work
	editor_command = "nvim --cmd 'let g:flatten_wait=1' --cmd 'cnoremap wq write<bar>bdelete<bar>startinsert'",

	-- flat config options, see toggleterm.nvim for valid options
	float_opts = {
		border = "none",
		width = function()
			return math.floor(vim.api.nvim_win_get_width(0) * 0.95)
		end,
		height = function()
			return math.floor(vim.api.nvim_win_get_height(0) * 0.95)
		end,
	},

	-- action key for adding files to aider from fzf-lua file pickers
	fzf_action_key = "ctrl-l",
	-- action key for adding files to aider from Telescope file pickers
	telescope_action_key = "<C-l>",

	-- filter `Telescope model_picker` model picker
	model_picker_search = { "^anthropic/", "^openai/", "^gemini/" },

	-- auto insert mode
	auto_insert = true,

	-- additional arguments for aider CLI
	aider_args = {},

	-- always start aider on startup
	spawn_on_startup = false,

	-- restart aider when directory changes
	-- aider.nvim will keep separate terminal for each directory so restarting isn't typically necessary
	restart_on_chdir = false,

	-- function to run (e.x. for term mappings) when terminal is opened
	on_term_open = nil,

	-- function to run when aider updates file/s, useful for triggering git diffs
	after_update_hook = nil,

	-- used to determine whether to use dark themes for code blocks and whether to use `--dark-mode`
	-- if supported theme is not available
	dark_mode = function()
		return vim.o.background == "dark"
	end,

	-- auto scroll terminal on output
	auto_scroll = true,

	win = {
		-- type of window layout to use
		direction = "vertical", -- can be 'float', 'vertical', 'horizontal', 'tab'
		-- size function for terminal
		size = function(term)
			if term.direction == "horizontal" then
				return math.floor(vim.api.nvim_win_get_height(0) * 0.4)
			elseif term.direction == "vertical" then
				return math.floor(vim.api.nvim_win_get_width(0) * 0.4)
			end
		end,
	},
	-- theme colors for aider
	theme = nil,
}

---@class AiderConfig
M.config = {}

---@type tokyonight.HighlightsFn
local function set_tokyonight_theme(c, _)
	return {
		user_input_color = c.git.add,
		tool_output_color = c.blue,
		tool_error_color = c.red1,
		tool_warning_color = c.orange,
		assistant_output_color = c.purple,
		completion_menu_color = c.fg_float,
		completion_menu_bg_color = c.bg_float,
		completion_menu_current_color = c.fg_dark,
		completion_menu_current_bg_color = c.bg_highlight,
	}
end

---@param c table
local function set_catppuccin_colors(c)
	return {
		user_input_color = c.green,
		tool_output_color = c.blue,
		tool_error_color = c.red,
		tool_warning_color = c.yellow,
		assistant_output_color = c.mauve,
		completion_menu_color = c.text,
		completion_menu_bg_color = c.base,
		completion_menu_current_color = c.crust,
		completion_menu_current_bg_color = c.pink,
	}
end

local function setup_tokyonight()
	if not vim.startswith(vim.g.colors_name, "tokyonight") then
		return -- Do nothing if tokyonight is not active
	end
	local ok, tokyonight_config = pcall(require, "tokyonight.config")
	if not ok then
		return -- Do nothing if tokyonight.config is not found
	end
	local opts = tokyonight_config.options
	local ok, tokyonight_colors = pcall(require, "tokyonight.colors")
	if not ok then
		return -- Do nothing if tokyonight.colors is not found
	end
	return set_tokyonight_theme(tokyonight_colors.setup(opts), opts)
end

local function setup_catppuccin()
	local ok, _ = pcall(require, "catppuccin.palettes")
	if not ok then
		return
	end

	local current_color = vim.g.colors_name
	local flavour = require("catppuccin").flavour or vim.g.catppuccin_flavour

	if current_color and current_color:match("^catppuccin") and flavour then
		local colors = require("catppuccin.palettes").get_palette()
		return set_catppuccin_colors(colors)
	end
	return
end

---Initialize configuration with user options
---@param opts AiderConfig|nil User configuration options
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", {}, M.defaults, opts)

	local theme = setup_tokyonight() or setup_catppuccin()
	if theme then
		M.config.theme = theme
	end
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
