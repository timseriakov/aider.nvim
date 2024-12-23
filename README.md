# aider.nvim

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

## Features

- Defaults to using the `--watch-file` [feature](https://aider.chat/docs/config/options.html#--watch-files)
  - Aider will automatically startup when valid [comments](https://aider.chat/docs/config/options.html#--watch-files) are written
  - Aider will auto-detect `ai`, `ai!` and `ai?` [comments](https://aider.chat/docs/config/options.html#--watch-files)
  - When comment is a question (`ai?`) aider will automatically show the terminal
  - All files with AI comments will get added to aider automatically
- Get live streamed notifications as Aider is processing
- The terminal will automatically be brought to the foreground if Aider prompts for input
- Auto reload all files changed by Aider
- Add configurable hooks to run when Aider finishes updating a file
  - For example, you can use [diffview](https://github.com/sindrets/diffview.nvim) to always show a gorgeous diff
- Send commands to Aider explicitly with `AiderSend <cmd>`
  - Can be used to create custom prompts
- Toggle Aider terminal window and bring to background/foreground at any time, with multiple window formats
- Load files into Aider session
  - You can use fzf-lua or telescope to select files (multi-select supported) with multiple file viewers:
    - Telescope git_files | find_files | buffers | oldfiles
    - FZF-Lua any file finder that follows standard conventions for passing file params
  - When not it watch mode `AiderLoad` without args can be used to `/add` the current file, or specify file args
- Ask questions about code with visual selection support
  - `AiderAsk` with a visual selection will prompt you for input and add the selected code to the prompt
- For diff viewing, accepting or rejecting changes:
  - Use [diffview](https://github.com/sindrets/diffview.nvim) which can auto trigger after Aider makes changes (see below).
  - Use [gitsigns](https://github.com/lewis6991/gitsigns.nvim) to stage/view/undo/navigate hunks
- Supports switching to different repos and will maintain context per repo
- Telescope picker for selecting models `:Telescope model_picker`
  - Use `model_picker_search = { "^anthropic/", "^openai/" }` to specify which models to look for
- Integration with tokyonight and catppuccin themes

## Prerequisites

- Neovim 0.5+
- [Aider](https://github.com/paul-gauthier/aider) required bo to be installed and available in `PATH` (`pip install aider-chat`)
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) is required for terminal management
- [diffview](https://github.com/sindrets/diffview.nvim)is optional but it is a great way to view Aider's changes, revert or undo them, see integration bellow
- [fidget](https://github.com/j-hui/fidget.nvim) is optional but it is the recommended way to show Aider activity, see configuration bellow
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced file selection)
- [willothy/flatten.nvim](https://github.com/willothy/flatten.nvim) (only if you want to use `/editor` command)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  {
    "aweis89/aider.nvim",
    dependencies = {
       -- required for core functionality
      "akinsho/toggleterm.nvim",

       -- for fuzzy file `/add`ing functionality ("ibhagwan/fzf-lua" supported as well)
      "nvim-telescope/telescope.nvim",

      -- Optional, but great for diff viewing and after_update_hook integration
      "sindrets/diffview.nvim",

      -- Optional but great option for viewing Aider output
      "j-hui/fidget.nvim",

      -- Only if you care about using the /editor command
      "willothy/flatten.nvim",
    },
    lazy = false,
    opts = {
      -- Auto trigger diffview after Aider's file changes
      after_update_hook = function()
        require("diffview").open({ "HEAD^" })
      end,
    },
    keys = {
      {
        "<C-x>",
        "<cmd>AiderToggle<CR>",
        desc = "Toggle Aider",
        mode = { "i", "t", "n" },
      },
      {
        "<leader>as",
        "<cmd>AiderSpawn<CR>",
        desc = "Toggle Aidper (default)",
      },
      {
        "<leader>au",
        "<cmd>AiderSend /undo<CR>",
        desc = "Aider undo",
      },
      {
        "<leader>ams",
        "<cmd>AiderSend /model sonnet<CR>",
        desc = "Switch to sonnet",
      },
      {
        "<leader>amh",
        "<cmd>AiderSend /model haiku<CR>",
        desc = "Switch to haiku",
      },
      {
        "<leader>al",
        "<cmd>AiderLoad<CR>",
        desc = "Add file to aider",
      },
      {
        "<leader>ad",
        "<cmd>AiderAsk<CR>",
        desc = "Ask with selection",
        mode = { "v", "n" },
      },
    },
  },
}
```

### Using [Packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
require('packer').startup(function(use)
  use {
    "aweis89/aider.nvim",
    dependencies = {
      -- required for core functionality
      "akinsho/toggleterm.nvim",

      -- for fuzzy file `/add`ing functionality ("ibhagwan/fzf-lua" supported as well)
      "nvim-telescope/telescope.nvim",

      -- Optional, but great for diff viewing and after_update_hook integration
      "sindrets/diffview.nvim",

      -- Optional but great option for viewing Aider output
      "j-hui/fidget.nvim",

      -- Only if you care about using the /editor command
      "willothy/flatten.nvim",
    },
    config = function()
      require('aider').setup({
        -- Auto trigger diffview after Aider's file changes
        after_update_hook = function()
          require("diffview").open({ "HEAD^" })
        end,
      })

      -- Add keymaps
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>as', '<cmd>AiderSpawn<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Aider (default)' }))
      vim.keymap.set('n', '<leader>au', '<cmd>AiderSend /undo<CR>', vim.tbl_extend('force', opts, { desc = 'Aider undo' }))
      vim.keymap.set({ 'i', 't', 'n' }, '<C-x>', '<cmd>AiderToggle<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Aider' }))
      vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', vim.tbl_extend('force', opts, { desc = 'Add file to aider' }))
      vim.keymap.set({ 'v', 'n' }, '<leader>ad', '<cmd>AiderAsk<CR>', vim.tbl_extend('force', opts, { desc = 'Ask with selection' }))
      vim.keymap.set('n', '<leader>ams', '<cmd>AiderSend /model sonnet<CR>', vim.tbl_extend('force', opts, { desc = 'Switch to sonnet' }))
      vim.keymap.set('n', '<leader>amh', '<cmd>AiderSend /model haiku<CR>', vim.tbl_extend('force', opts, { desc = 'Switch to haiku' }))
    end
  }
end)
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```lua
call plug#begin()
Plug 'aweis89/aider.nvim'
Plug 'akinsho/toggleterm.nvim'
Plug 'nvim-telescope/telescope.nvim' -- for fuzzy file `/add`ing functionality
Plug 'sindrets/diffview.nvim' -- Optional, but great for diff viewing
Plug 'j-hui/fidget.nvim' -- Optional but great option for viewing Aider output
Plug 'willothy/flatten.nvim' -- Only if you care about using /editor command

lua << EOF
require('aider').setup({
  -- Auto trigger diffview after Aider's file changes
  after_update_hook = function()
    require("diffview").open({ "HEAD^" })
  end,
})

-- Add keymaps
vim.keymap.set('n', '<leader>as', '<cmd>AiderSpawn<CR>', { noremap = true, silent = true, desc = 'Toggle Aider (default)' })
vim.keymap.set('n', '<leader>au', '<cmd>AiderSend /undo<CR>', { noremap = true, silent = true, desc = 'Aider undo' })
vim.keymap.set({ 'i', 't', 'n' }, '<C-x>', '<cmd>AiderToggle<CR>', { noremap = true, silent = true, desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { noremap = true, silent = true, desc = 'Add file to aider' })
vim.keymap.set({ 'v', 'n' }, '<leader>ad', '<cmd>AiderAsk<CR>', { noremap = true, silent = true, desc = 'Ask with selection' })
vim.keymap.set('n', '<leader>ams', '<cmd>AiderSend /model sonnet<CR>', { noremap = true, silent = true, desc = 'Switch to sonnet' })
vim.keymap.set('n', '<leader>amh', '<cmd>AiderSend /model haiku<CR>', { noremap = true, silent = true, desc = 'Switch to haiku' })
EOF
call plug#end()
```

## Commands

- `:AiderToggle [direction]` - Toggle the Aider terminal window. Optional direction can be:

  - `vertical` - Switch to vertical split
  - `horizontal` - Switch to horizontal split
  - `float` - Switch to floating window (default)
  - `tab` - Switch to new tab
  - When called without a direction argument, it opens in the to the last specified direction (or the toggleterm specified default). With a direction argument, it will switch the terminal to that layout (even if already open).

- `:AiderLoad [files...]` - Load files into Aider session, defaults to the current file when no args are specified
- `:AiderAsk [prompt]` - Ask a question about code using the /ask command. If no prompt is provided, it will open an input popup. In visual mode, the selected text is appended to the prompt.
- `:AiderSend [command]` - Send any command to Aider. In visual mode, the selected text is appended to the command.

## FZF-lua Integration

When fzf-lua is installed, you can use `Ctrl-l` in the file picker to load files into Aider:

- Single file: Navigate to a file and press `Ctrl-l` to load it into Aider
- Multiple files: Use `Shift-Tab` to select multiple files, then press `Ctrl-l` to load all selected files
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground
- FZF also support a select-all behavior, which can be used to load all files matching a suffix for example

## Telescope Integration

When Telescope is installed, you can use `<C-l>` load files into Aider:

- Current pickers with this registered action include: find_files, git_files, buffers and oldfiles
- Single file: Navigate to a file and press `<C-l>` to load it into Aider.
- Multiple files: Use multi-select to choose files (default <tab>), then press `<C-l>` to load all selected files.
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active.
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground

## Configuration

The plugin can be configured during setup:

```lua
require('aider').setup({
 -- start aider when ai comment is written (e.x. `ai!|ai?|ai`)
 spawn_on_comment = true,

 -- auto show aider terminal when trigging /ask with `ai?` comment
 auto_show_on_ask = true,

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
  style = "minimal",
 },

 -- print logs of Aider's output in the right corner, requires fidget.nvim
 log_notifier = true,

 -- code theme to use for markdown blocks when in dark mode
 code_theme_dark = "monokai",

 -- code theme to use for markdown blocks when in light mode
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

 -- function to run (e.x. for term mappings) when terminal is opened
 on_term_open = nil,

 -- used to determine whether to use dark themes for code blocks and whether to use `--dark-mode`
 -- if supported theme is not available
 dark_mode = function()
  return vim.o.background == "dark"
 end,
 -- auto scroll terminal on output
 auto_scroll = true,
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
   border = "none",
   width = function()
    return math.floor(vim.api.nvim_win_get_width(0) * 0.95)
   end,
   height = function()
    return math.floor(vim.api.nvim_win_get_height(0) * 0.95)
   end,
  },
 },
 -- theme colors for aider
 theme = nil,
})
```

### Auto Dark Mode Detection

The plugin automatically sets the `--dark-mode` flag when Neovim's `background` option is set to "dark". This ensures aider's UI matches your Neovim theme.

## License

MIT
