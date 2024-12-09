# aider.nvim

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

> ⚠️ **Warning**: This plugin is under rapid development and breaking changes may occur. If you encounter any issues, please [file an issue](https://github.com/aweis89/aider.nvim/issues) on GitHub.

## Features

- Optionally start Aider automatically in the background (default)
- When in background mode (default):
  - Get live streamed notifications as Aider is processing
  - The terminal will automatically be brought to the foreground if Aider prompts for input
  - Will default to using the `--watch-file`
    - So that all open files will get added to Aider automatically
    - Aider will auto-detect `AI` and `AI!` [comments](https://aider.chat/docs/config/options.html#--watch-files)
- Add configurable hooks to run when Aider finishes updating a file
  - For example, you can use [diffview](https://github.com/sindrets/diffview.nvim) to always show a gorgeous diff
- Send commands to Aider explicitly with `AiderSend <cmd>`
  - Can be used to create custom prompts
- Toggle Aider terminal window and bring to background/foreground at any time, with multiple window formats
- Load files into Aider session
  - When not it watch mode `AiderLoad` without args can be used to `/add` the current file or specify file args
  - You can use fzf-lua or telescope to select files (multi-select supported) with any file viewer (git_files, buffers..)
- Ask questions about code with visual selection support
  - `AiderAsk` with a visual selection will prompt you for input and add the selected code to the prompt
- For diff viewing, accepting or rejecting changes, have a look at:
  - Use [diffview](https://github.com/sindrets/diffview.nvim) which can auto trigger after Aider makes changes (see below).
  - Use [gitsigns](https://github.com/lewis6991/gitsigns.nvim) to stage/view/undo/navigate hunks

## Prerequisites

- Neovim 0.5+
- [Aider](https://github.com/paul-gauthier/aider) installed (`pip install aider-chat`)
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) (required for terminal management)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced file selection)
- [willothy/flatten.nvim](https://github.com/willothy/flatten.nvim) (only if you want to use `/editor` command)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  {
    "aweis89/aider.nvim",
    dependencies = {
      "akinsho/toggleterm.nvim",
      "nvim-telescope/telescope.nvim", -- or "ibhagwan/fzf-lua"
      "willothy/flatten.nvim", -- only if you care about using /editor command
    },
    lazy = false,
    opts = {
      after_update_hook = function()
        require("diffview").open({ "HEAD^" })
      end,
    },
    keys = {
      {
        "<leader>as",
        "<cmd>AiderSpawn<CR>",
        desc = "Toggle Aidper (default)",
      },
      {
        "<leader>ac",
        "<cmd>AiderSend /commit<CR>",
        desc = "Aider commit",
      },
      {
        "<leader>a<space>",
        "<cmd>AiderToggle<CR>",
        desc = "Toggle Aider",
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
    requires = {
      "akinsho/toggleterm.nvim",
      "nvim-telescope/telescope.nvim", -- or "ibhagwan/fzf-lua"
      "willothy/flatten.nvim", -- only if you care about using /editor command
    },
    config = function()
      require('aider').setup({
        after_update_hook = function()
          require("diffview").open({ "HEAD^" })
        end
      })
    end
  }
end)
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```lua
call plug#begin()
Plug 'aweis89/aider.nvim'
Plug 'akinsho/toggleterm.nvim'
Plug 'nvim-telescope/telescope.nvim' " or 'ibhagwan/fzf-lua'
Plug 'willothy/flatten.nvim' " only if you care about using /editor command

lua << EOF
require('aider').setup({
  after_update_hook = function()
    require("diffview").open({ "HEAD^" })
  end
})
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

When Telescope is installed, you can use `<C-l>` in any file picker to load files into Aider:

- Single file: Navigate to a file and press `<C-l>` to load it into Aider.
- Multiple files: Use multi-select to choose files, then press `<C-l>` to load all selected files.
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active.
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground

## Configuration

The plugin can be configured during setup:

```lua
require('aider').setup({
 -- Enable the new `--watch-files` feature so Aider will auto respond to AI/AI! comments
 watch_files = true,

 -- Always start Aider so it's ready to react to your comments.
 -- Alternatively run `AiderSpawn` manually to start on-demand
 spawn_on_startup = true,

 -- Editor command to run when triggered via `/editor`.
 -- Defaults to using flatten plugin to trigger a none-nested neovim session
 editor_command = nil,

 -- Trigger key to run when in fzf-lua to `/add` selected file/s to Aider.
 fzf_action_key = "ctrl-l",
 -- Trigger key to run when in telescope to `/add` selected file/s to Aider.
 telescope_action_key = "<C-l>",

 -- Command used to notify on Aider activity.
 -- For a low-intrusive option, enable [fidget](https://github.com/j-hui/fidget.nvim)
 -- e.x. `notify = require("fidget").notify
 notify = vim.notify,

 -- Add additional args to aider,
 -- .e.x `aider_args = "--no-git"` to disable auto git commits.
 aider_args = "",

 -- Add additional commands to run after Aider updates file/s.
 -- E.x. you can auto trigger diffs with the diffview plugin.
 -- With `--no-git` diff unstaged changes: `after_update_hook = function() require("diffview").open({}) end`
 -- Or with git enabled diff the last commit: `after_update_hook = function() require("diffview").open({'HEAD^'}) end`
 after_update_hook = nil,

 toggleterm = {
  -- default direction when none specified, can be 'vertical' | 'horizontal' | 'tab' | 'float'
  direction = "vertical",

  -- specify a size for the horizontal or vertical
  size = function(term)
   if term.direction == "horizontal" then
    return math.floor(vim.api.nvim_win_get_height(0) * 0.4)
   elseif term.direction == "vertical" then
    return math.floor(vim.api.nvim_win_get_width(0) * 0.4)
   end
  end,
 },
})
```

### Auto Dark Mode Detection

The plugin automatically sets the `--dark-mode` flag when Neovim's `background` option is set to "dark". This ensures aider's UI matches your Neovim theme.

## License

MIT
