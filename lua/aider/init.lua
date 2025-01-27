---@class ToggletermConfig
---@field direction string Window layout type ('float'|'vertical'|'horizontal'|'tab')
---@field size function Size function for terminal
---@field float_opts table<string, any>? flat config options, see toggleterm.nvim for valid options

---@class FuzzyFinderMappings
---@field add string
---@field read_only string
---@field drop string

---@class AiderConfig
---@field spawn_on_comment boolean
---@field editor_command string|nil Command to use for editor
---@field fzf_action_key string|nil Key to trigger aider load in fzf
---@field aider_args table Additional arguments for aider CLI
---@field win ToggletermConfig window options
---@field spawn_on_startup boolean|nil
---@field after_update_hook function|nil
---@field watch_files boolean
---@field telescope_action_key string|nil
---@field auto_insert true
---@field dark_mode function|boolean
---@field model_picker_search table
---@field on_term_open function|nil
---@field restart_on_chdir boolean
---@field theme table|nil
---@field code_theme_dark string
---@field code_theme_light string
---@field progress_notifier table|nil
---@field log_notifier boolean
---@field git_pager string
---@field auto_show table
---@field telescope FuzzyFinderMappings
---@field fzf FuzzyFinderMappings
---@field test_command string|nil
---@field use_git_stash boolean

local M = {}

---Default configuration values
---@type AiderConfig
M.defaults = {
  -- start aider when ai comment is written (e.x. `ai!|ai?|ai`)
  spawn_on_comment = true,

  -- auto show aider terminal window
  auto_show = {
    on_ask = true,         -- e.x. `ai? comment`
    on_change_req = true,  -- e.x. `ai! comment`
    on_command_send = true -- e.x. when running `AiderSend ..` or `AiderLoad`
  },

  -- function to run when aider updates file/s, useful for triggering git diffs
  after_update_hook = function()
    local config = require("aider").config
    local stashed_changes = require("aider.commands").stashed_workdir
    if config.use_git_stash and stashed_changes then
      if not require("aider.snacks_picker").aider_changes() then
        return
      end
      local ok, diffview = pcall(require, "diffview")
      if ok then
        diffview.open({ "stash@{0}..stash@{1}" })
        return
      end
    end
  end,

  use_git_stash = true,

  -- deprecated: use telescope.add and telescope.read_only instead
  telescope_action_key = nil,
  telescope = {
    -- Runs `/add <files>` for selected entries (with multi-select supported)
    add = "<C-l>",
    -- Runs `/read-only <files>` for selected entries (with multi-select supported)
    read_only = "<c-r>",
    -- Runs `/drop`` <files> for selected entries (with multi-select supported)
    drop = "<c-z>",
  },
  -- deprecated: use fzf.add and fzf.read_only instead
  fzf_action_key = nil,
  fzf = {
    -- Runs `/add <files>` for selected entries (with multi-select supported)
    add = "ctrl-l",
    -- Runs `/read-only <files>` for selected entries (with multi-select supported)
    read_only = "ctrl-r",
    -- Runs `/drop`` <files> for selected entries (with multi-select supported)
    drop = "ctrl-z",
  },

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
  log_notifier = false,

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
  on_term_open = nil,

  test_command = nil,
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

  require("aider.snacks_picker").setup(M.config)

  -- Setup telescope integration if available
  local telescope_ok, telescope = pcall(require, "telescope")
  if telescope_ok then
    telescope.load_extension("file_pickers")
    telescope.load_extension("model_picker")
  end
  require("aider.commands").setup(M.config)
end

return M
