---@class ToggletermConfig
---@field direction string Window layout type ('float'|'vertical'|'horizontal'|'tab')
---@field size function Size function for terminal
---@field float_opts table<string, any>? flat config options, see toggleterm.nvim for valid options

---@class AiderConfig
---@field spawn_on_comment boolean
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string Key to trigger aider load in fzf
---@field aider_args table Additional arguments for aider CLI
---@field win ToggletermConfig window options
---@field spawn_on_startup boolean|nil
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
---@field git_pager string
---@field use_tmux boolean
---@field auto_show table

local M = {}

-- Table to store temporary file names
vim.g.aider_temp_files = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
	-- start aider when ai comment is written (e.x. `ai!|ai?|ai`)
	spawn_on_comment = true,

	-- auto show aider terminal window
	auto_show = {
		on_ask = true, -- e.x. `ai? comment`
		on_change_req = false, -- e.x. `ai! comment`
		on_file_add = false, -- e.x. when using Telescope or `AiderLoad` to add files
	},

	-- function to run when aider updates file/s, useful for triggering git diffs
	after_update_hook = nil,

	-- action key for adding files to aider from fzf-lua file pickers
	fzf_action_key = "ctrl-l",

	-- action key for adding files to aider from Telescope file pickers
	telescope_action_key = "<C-l>",

	-- filter `Telescope model_picker` model picker
	model_picker_search = { "^anthropic/", "^openai/", "^gemini/" },

	-- enable the --watch-files flag for Aider
	-- Aider will automatically start when valid comments are created
	watch_files = true,

	-- for snacks progress notifications
	progress_notifier = {
		style = "compact",
		-- * compact: use border for icon and title
		-- * minimal: no border, only icon and message
		-- * fancy: similar to the default nvim-notify style
	},

	-- print logs of Aider's output in the right corner, requires fidget.nvim
	log_notifier = true,

	-- code theme to use for markdown blocks when in dark mode
	-- code_theme_dark = "gruvbox-dark",
	code_theme_dark = "monokai",

	-- code theme to use for markdown blocks when in light mode
	-- code_theme_light = "gruvbox-light",
	code_theme_light = "default",

	-- command to run for opening nested editor when invoking `/editor` from Aider terminal
	-- requires flatten.nvim to work
	editor_command = "nvim --cmd 'let g:flatten_wait=1' --cmd 'cnoremap wq write<bar>bdelete<bar>startinsert'",

	-- auto insert mode
	auto_insert = true,

	-- additional arguments for aider CLI
	aider_args = {},

	-- always start aider on startup
	spawn_on_startup = false,

	-- restart aider when directory changes
	-- aider.nvim will keep separate terminal for each directory so restarting isn't typically necessary
	restart_on_chdir = false,

	-- used to determine whether to use dark themes for code blocks and whether to use `--dark-mode`
	-- if supported theme is not available
	dark_mode = function()
		return vim.o.background == "dark"
	end,

	-- auto scroll terminal on output
	auto_scroll = false,

	-- window layout settings
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
		-- flat config options, see toggleterm.nvim for valid options
		float_opts = {
			border = "single",
			width = function()
				return vim.api.nvim_win_get_width(0)
			end,
			height = function()
				return vim.api.nvim_win_get_height(0)
			end,
		},
	},
	-- theme colors for aider
	theme = {},

	-- git pager to use, defaults to 'cat' to prevent blocking after_update_hook
	git_pager = "cat",

	-- function to run (e.x. for term mappings) when terminal is opened
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
		vim.opt.number = false
		vim.opt.wrap = true
		vim.opt.showbreak = ""
	end,

	-- enable tmux mode (highly experimental!)
	use_tmux = false,
}

---@class AiderConfig
M.config = {}

---Initialize configuration with user options
---@param opts AiderConfig|nil User configuration options
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", {}, M.defaults, opts)

	local theme_mod = require("aider.theme")
	local theme = theme_mod.tokyonight_theme() or theme_mod.catppuccin_theme() or theme_mod.gruvbox_theme()
	if theme then
		M.config.theme = theme
	end

	-- Setup fzf-lua integration if available
	require("aider.fzf").setup(M.config)

	-- Setup telescope integration if available
	local telescope_ok, telescope = pcall(require, "telescope")
	if telescope_ok then
		telescope.load_extension("file_pickers")
		telescope.load_extension("model_picker")
	end
	require("aider.commands").setup(M.config)
end

return M
