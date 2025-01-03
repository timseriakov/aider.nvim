# 🤝 aider.nvim

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

## ✨ Features

- Automatically start Aider with `--watch-files` when valid [comments](https://aider.chat/docs/config/options.html#--watch-files) are written ✍️
- For `ai?` (question) comments, Aider.nvim automatically shows the terminal ❓
- Get live streamed notifications as Aider is processing (both a spinner and logs) ⚡️
- Aider.nvim automatically brings the terminal to the foreground when Aider prompts for user confirmation (e.x. asking to scrape a URL) 💬
- Add configurable hooks to run when Aider finishes updating a file 🪝
  - For example, you can use [diffview](https://github.com/sindrets/diffview.nvim) to always show a gorgeous diff 🤩
- Explicitly send commands to Aider using `AiderSend <cmd>` প্রেরণ
  - Can be used to create custom prompts or custom keymaps to any Aider command 🎨
- Toggle the Aider terminal to different window formats (defaults to vertical split) and background/foreground 💻
- Load files into the current Aider session 📂
  - For both Telescope and fzf-lua, custom file actions (with multi-select support) are added to `git_files`, `find_files`, `buffers`, and `oldfiles` for 📄
    - Adding files `/add <selection>`
    - Adding files for read-only `/read-only <selection>`
    - Dropping files `/drop <selection>`
  - Use `AiderAdd` without arguments to add the current file (`/add`), or specify file arguments ➕
- Ask questions about your code, with support for visual selections ❓
  - `AiderAsk` with a visual selection will prompt you for input and add the selected code to the prompt (with metadata about it's source) 🙋
- For diff viewing, accepting or rejecting changes: 🔍
  - Optionally, use [diffview](https://github.com/sindrets/diffview.nvim) to automatically display diffs after Aider modifies files (see integration details below) ✅
  - Use [gitsigns](https://github.com/lewis6991/gitsigns.nvim) to stage/view/undo/navigate hunks 🧑‍💻
- Supports switching between different Git repositories, maintaining context for each 🔀
- Use the Telescope model picker (`:Telescope model_picker`) to select different AI models 🔭
  - Use `model_picker_search = { "^anthropic/", "^openai/" }` to specify which models to look for 🔎
- Theme support
  - For best theme support (inluding markdown code in Aider) use [isonleao/gruvbox.nvim](https://github.com/isonleao/gruvbox.nvim)
  - Also supports tokyonight and catppuccin themes (albeit without matching themes for markdown code blocks)

## 🆕 What's New

- Use `AiderFixDiagnostics` to send neovim diagnostics to Aider for fixing 🛠️
  - This typically includes both LSP and linting diagnostics
  - Additionally other plugins often integrate with neovim's diagnostics, so this can be a powerful tool for fixing issues in your codebase. For example [Neotest](https://github.com/nvim-neotest/neotest) has an option `neotest.diagnostic = true` which adds failing tests to diagnostics, which can then be sent to Aider for fixing using this command 💡
- Added full theme support for gruvbox when using [isonleao/gruvbox.nvim](https://github.com/isonleao/gruvbox.nvim), including matching code-block themes 🌈
- Defaulted `log_notifier` to `false` for a cleaner notification system that relies on the snacks progress spinner ⚡️

## 🛠️ Prerequisites

- Neovim 0.5+
- [Aider](https://github.com/paul-gauthier/aider) is required to be installed and available in `PATH` (`pip install aider-chat`) 💻
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) is required for terminal management 🧑‍💻
- [diffview](https://github.com/sindrets/diffview.nvim) is optional but highly recommended for visualizing, reverting, or undoing Aider's changes 🔍
- [snacks](https://github.com/folke/snacks.nvim) is optional but displays a spinner while Aider is active 🔄
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) are optional but enhance file selection 🔍
- [willothy/flatten.nvim](https://github.com/willothy/flatten.nvim) (only if you want to use `/editor` command) 🧑‍💻

## 📦 Installation

Install `aider.nvim` using your preferred plugin manager:

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

      -- Optional but will show aider spinner whenever active
      "folke/snacks.nvim",

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
        "<leader>as",
        "<cmd>AiderSpawn<CR>",
        desc = "Toggle Aidper (default)",
      },
      {
        "<leader>a<space>",
        "<cmd>AiderToggle<CR>",
        desc = "Toggle Aider",
      },
      {
        "<leader>af",
        "<cmd>AiderToggle float<CR>",
        desc = "Toggle Aider Float",
      },
      {
        "<leader>av",
        "<cmd>AiderToggle vertical<CR>",
        desc = "Toggle Aider Float",
      },
      {
        "<leader>al",
        "<cmd>AiderAdd<CR>",
        desc = "Add file to aider",
      },
      {
        "<leader>ad",
        "<cmd>AiderAsk<CR>",
        desc = "Ask with selection",
        mode = { "v", "n" },
      },
      {
        "<leader>am",
        desc = "Change model",
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
        "<leader>amg",
        "<cmd>AiderSend /model gemini/gemini-exp-1206<CR>",
        desc = "Switch to haiku",
      },
      {
        "<C-x>",
        "<cmd>AiderToggle<CR>",
        desc = "Toggle Aider",
        mode = { "i", "t", "n" },
      },
      -- Helpful mappings to utilize to manage aider changes
      {
        "<leader>ghh",
        "<cmd>Gitsigns change_base HEAD^<CR>",
        desc = "Gitsigns pick reversals",
      },
      {
        "<leader>dvh",
        "<cmd>DiffviewOpen HEAD^<CR>",
        desc = "Diffview HEAD^",
      },
      {
        "<leader>dvo",
        "<cmd>DiffviewOpen<CR>",
        desc = "Diffview",
      },
      {
        "<leader>dvc",
        "<cmd>DiffviewClose!<CR>",
        desc = "Diffview close",
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

      -- Optional but will show aider spinner whenever active
      "folke/snacks.nvim",

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
      vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Aider' }))
      vim.keymap.set('n', '<leader>af', '<cmd>AiderToggle float<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Aider Float' }))
      vim.keymap.set('n', '<leader>av', '<cmd>AiderToggle vertical<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Aider Vertical' }))
      vim.keymap.set('n', '<leader>al', '<cmd>AiderAdd<CR>', vim.tbl_extend('force', opts, { desc = 'Add file to aider' }))
      vim.keymap.set({ 'v', 'n' }, '<leader>ad', '<cmd>AiderAsk<CR>', vim.tbl_extend('force', opts, { desc = 'Ask with selection' }))
      vim.keymap.set('n', '<leader>am', '<cmd>Telescope model_picker<CR>', vim.tbl_extend('force', opts, { desc = 'Change model' }))
      vim.keymap.set('n', '<leader>ams', '<cmd>AiderSend /model sonnet<CR>', vim.tbl_extend('force', opts, { desc = 'Switch to sonnet' }))
      vim.keymap.set('n', '<leader>amh', '<cmd>AiderSend /model haiku<CR>', vim.tbl_extend('force', opts, { desc = 'Switch to haiku' }))
      vim.keymap.set('n', '<leader>amg', '<cmd>AiderSend /model gemini/gemini-exp-1206<CR>', vim.tbl_extend('force', opts, { desc = 'Switch to Gemini' }))
      vim.keymap.set({ 'i', 't', 'n' }, '<C-x>', '<cmd>AiderToggle<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Aider' }))
      vim.keymap.set('n', '<leader>au', '<cmd>AiderSend /undo<CR>', vim.tbl_extend('force', opts, { desc = 'Aider undo' }))
      -- Helpful mappings to utilize to manage aider changes
      vim.keymap.set('n', '<leader>ghh', '<cmd>Gitsigns change_base HEAD^<CR>', vim.tbl_extend('force', opts, { desc = 'Gitsigns pick reversals' }))
      vim.keymap.set('n', '<leader>dvh', '<cmd>DiffviewOpen HEAD^<CR>', vim.tbl_extend('force', opts, { desc = 'Diffview HEAD^' }))
      vim.keymap.set('n', '<leader>dvo', '<cmd>DiffviewOpen<CR>', vim.tbl_extend('force', opts, { desc = 'Diffview' }))
      vim.keymap.set('n', '<leader>dvc', '<cmd>DiffviewClose!<CR>', vim.tbl_extend('force', opts, { desc = 'Diffview close' }))
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
Plug 'folke/snacks.nvim' -- Optional but will show aider spinner whenever active
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
vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { noremap = true, silent = true, desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>af', '<cmd>AiderToggle float<CR>', { noremap = true, silent = true, desc = 'Toggle Aider Float' })
vim.keymap.set('n', '<leader>av', '<cmd>AiderToggle vertical<CR>', { noremap = true, silent = true, desc = 'Toggle Aider Vertical' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderAdd<CR>', { noremap = true, silent = true, desc = 'Add file to aider' })
vim.keymap.set({ 'v', 'n' }, '<leader>ad', '<cmd>AiderAsk<CR>', { noremap = true, silent = true, desc = 'Ask with selection' })
vim.keymap.set('n', '<leader>am', '<cmd>Telescope model_picker<CR>', { noremap = true, silent = true, desc = 'Change model' })
vim.keymap.set('n', '<leader>ams', '<cmd>AiderSend /model sonnet<CR>', { noremap = true, silent = true, desc = 'Switch to sonnet' })
vim.keymap.set('n', '<leader>amh', '<cmd>AiderSend /model haiku<CR>', { noremap = true, silent = true, desc = 'Switch to haiku' })
vim.keymap.set('n', '<leader>amg', '<cmd>AiderSend /model gemini/gemini-exp-1206<CR>', { noremap = true, silent = true, desc = 'Switch to Gemini' })
vim.keymap.set({ 'i', 't', 'n' }, '<C-x>', '<cmd>AiderToggle<CR>', { noremap = true, silent = true, desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>au', '<cmd>AiderSend /undo<CR>', { noremap = true, silent = true, desc = 'Aider undo' })
-- Helpful mappings to utilize to manage aider changes
vim.keymap.set('n', '<leader>ghh', '<cmd>Gitsigns change_base HEAD^<CR>', { noremap = true, silent = true, desc = 'Gitsigns pick reversals' })
vim.keymap.set('n', '<leader>dvh', '<cmd>DiffviewOpen HEAD^<CR>', { noremap = true, silent = true, desc = 'Diffview HEAD^' })
vim.keymap.set('n', '<leader>dvo', '<cmd>DiffviewOpen<CR>', { noremap = true, silent = true, desc = 'Diffview' })
vim.keymap.set('n', '<leader>dvc', '<cmd>DiffviewClose!<CR>', { noremap = true, silent = true, desc = 'Diffview close' })
EOF
call plug#end()
```

## ⌨️ Commands

- `:AiderToggle [direction]` - Toggle the Aider terminal window. Optional direction can be: 🧑‍💻
  - `vertical` - Switch to vertical split ↔️
  - `horizontal` - Switch to horizontal split ↕️
  - `float` - Switch to floating window 🪟
  - `tab` - Switch to new tab 📑 (best for fullscreen toggle)
  - Without a direction argument, it opens in the last specified direction (or the toggleterm specified default). With a direction argument, it will switch the terminal to that layout (even if already open).
- `:AiderAdd [files...]` - Add files to the Aider session. If no files are specified, the current file is added 📂
  - `:AiderLoad` is deprecated and will be removed in a future version - use `:AiderAdd` instead
- `:AiderReadOnly [files...]` - Add files to the Aider session in read-only mode. If no files are specified, the current file is added 📂
- `:AiderAsk [prompt]` - Ask a question using the `/ask` command. Without a prompt, an input popup will appear. In visual mode, the selected text is added to the prompt 🙋
- `:AiderSend [command]` - Send a command to Aider. In visual mode, the selected text is added to the command 📨
- `:AiderFixDiagnostics` Send neovim diagnostics to Aider for fixing. Either visual mode to send diagnostics for the selected text, or normal mode to send all of current files diagnostics

## 🤝 FZF-lua Integration

Integrating with fzf-lua allows for quick and efficient loading of files into Aider directly from the fzf-lua file pickers. When fzf-lua is installed, you can use mappings in the following native pickers:

- **Files**: Regular file picker (`:FzfLua files`)
- **Git Files**: Files tracked by Git (`:FzfLua git_files`)
- **Oldfiles**: Recently opened files (`:FzfLua oldfiles`)
- **Buffers**: Open buffers (`:FzfLua buffers`)
- **Git Status**: Modified/untracked files (`:FzfLua git_status`)

Usage:

- Load files: Navigate to files and press `Ctrl-l` to load them into Aider (supports multi-select) 📄
- Load read-only: Press `Ctrl-r` to load files in read-only mode (supports multi-select) 📄
- Remove files: Press `Ctrl-z` to remove files from Aider (supports multi-select) 🗑️
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active 🧑‍💻
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground 📂
  - Note: `AiderLoad` is deprecated - use `AiderAdd` instead

## 🔭 Telescope Integration

Telescope integration enables seamless file loading into Aider from various Telescope pickers. When Telescope is installed, you can use `<C-l>` load files into Aider:

- Current pickers with this registered action include: find_files, git_files, buffers and oldfiles 🔭
- Load files: Navigate to files and press `<C-l>` to load them into Aider (supports multi-select) 📄
- Load read-only: Press `<C-r>` to load files in read-only mode (supports multi-select) 📄
- Remove files: Press `<C-z>` to remove files from Aider (supports multi-select) 🗑️
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active. 🧑‍💻
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground 📂

## ⚙️ Configuration

The plugin can be configured during setup: 🧑‍💻

```lua
require('aider').setup({
  -- Automatically start Aider when an AI comment (`ai!`, `ai?`, or `ai`) is written
  spawn_on_comment = true,

  -- Automatically show aider terminal window
  auto_show = {
    on_ask = true, -- e.x. `ai? comment`
    on_change_req = false, -- e.x. `ai! comment`
    on_file_add = false, -- e.x. when using Telescope or `AiderLoad` to add files
  },

  -- function to run when aider updates file/s, useful for triggering git diffs
  after_update_hook = nil,

  -- Filters for the `Telescope model_picker`
  model_picker_search = { "^anthropic/", "^openai/", "^gemini/" "^deepseek/" },

  -- Enable the `--watch-files` flag for Aider, enabling automatic startup on valid comment creation
  watch_files = true,

  -- Configuration for `snacks.nvim` progress notifications
  progress_notifier = {
    style = "compact",
    -- * compact: use border for icon and title
    -- * minimal: no border, only icon and message
    -- * fancy: similar to the default nvim-notify style
  },

  -- Display Aider's logs using fidget.nvim (requires fidget.nvim)
  log_notifier = false,

  -- code theme to use for markdown blocks when in dark mode
  code_theme_dark = "monokai",

  -- code theme to use for markdown blocks when in light mode
  code_theme_light = "default",

  -- Command to open a nested editor when invoking `/editor` from the Aider terminal (requires `flatten.nvim`)
  editor_command = "nvim --cmd 'let g:flatten_wait=1' --cmd 'cnoremap wq write<bar>bdelete<bar>startinsert'",

  -- auto insert mode
  auto_insert = true,

  -- additional arguments for aider CLI
  aider_args = {},

  -- always start aider on startup
  spawn_on_startup = false,

  -- Restart Aider when the working directory changes.
  -- Note that `aider.nvim` maintains separate terminals for each directory, often making restarts unnecessary.
  restart_on_chdir = false,

  -- function to run (e.x. for term mappings) when terminal is opened
  on_term_open = nil,

  -- Determines whether to use dark themes for code blocks and the `--dark-mode` flag (if a supported theme is unavailable)
  dark_mode = function()
    return vim.o.background == "dark"
  end,
  -- auto scroll terminal on output
  auto_scroll = true,
  -- Window layout settings for the Aider terminal
  win = {
    -- type of window layout to use
    direction = "float", -- can be 'float', 'vertical', 'horizontal', 'tab'
    -- size function for terminal
    size = function(term)
      if term.direction == "horizontal" then
        return math.floor(vim.api.nvim_win_get_height(0) * 0.4)
      elseif term.direction == "vertical" then
        return math.floor(vim.api.nvim_win_get_width(0) * 0.4)
      end
    end,
    -- Flat configuration options (see `toggleterm.nvim` for valid options)
    float_opts = {
      border = "single",
      width = function()
        return math.floor(vim.api.nvim_win_get_width(0) * 0.95)
      end,
      height = function()
        return math.floor(vim.api.nvim_win_get_height(0) * 0.95)
      end,
    },
  },
  -- Telescope key mappings
  telescope = {
    -- Runs `/add <files>` for selected entries (with multi-select supported)
    add = "<C-l>",
    -- Runs `/read-only <files>` for selected entries (with multi-select supported)
    read_only = "<C-r>",
    -- Runs `/drop <files>` for selected entries (with multi-select supported)
    drop = "<C-z>",
  },
  -- fzf-lua key mappings
  fzf = {
    -- Runs `/add <files>` for selected entries (with multi-select supported)
    add = "ctrl-l",
    -- Runs `/read-only <files>` for selected entries (with multi-select supported)
    read_only = "ctrl-r",
    -- Runs `/drop <files>` for selected entries (with multi-select supported)
    drop = "ctrl-z",
    },
  },
  -- theme colors for aider
  theme = nil,

  -- The Git pager to use. Defaults to `cat` to prevent blocking the `after_update_hook`
  git_pager = "cat",

  -- Enable experimental tmux support
  use_tmux = false,
})
```

## Git Tips & Integration 🧑‍💻

### Recommended Git Practices 🧑‍🏫

To get the most out of `aider.nvim`, it's essential to use Git effectively. Git is the primary tool for managing and viewing changes made by Aider. Fortunately, Neovim offers excellent tools for Git integration, including `diffview`, `gitsigns`, and `telescope` (or fzf-lua). Familiarizing yourself with these tools and using them alongside `aider.nvim` will significantly enhance your Neovim Aider experience.

### Simplified Git Workflow (`--no-auto-commits`) 😌

For users less familiar with Git commands like `git reset`, a simplified workflow is available using the `--no-auto-commits` option. You can set this option via `aider_args` or in the `~/.aider.conf.yml` file. This approach simplifies the Git actions needed to manage Aider's changes, however, it reduces your ability to view prior changes that were overridden.

#### Visualizing Changes Without Auto-commits 🔍

With `--no-auto-commits`, Aider does not commit changes automatically, leaving them uncommitted in your working directory. Use the `after_update_hook` to visualize these changes with either `diffview` or `Telescope`:

```lua
-- Using diffview to show the diff:
after_update_hook = function()
  vim.cmd("DiffviewOpen")
end

-- Using telescope to show the diffs:
after_update_hook = function()
  vim.cmd("Telescope git_status")
end

-- Using fzf-lua to show the diffs:
after_update_hook = function()
  vim.cmd("FzfLua git_status")
end
```

These hooks display diffs of Aider's changes alongside other uncommitted modifications in your working directory. After reviewing, commit all changes to accept them, or use `gitsigns` for selective staging, unstaging, or reverting individual hunks or files.

#### Useful `gitsigns` Mappings 🧑‍💻

Here are some useful `gitsigns` mappings (adapted from LazyVim) that can help you manage changes when using this simplified workflow:

```lua
local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

map("n", "]h", function()
  if vim.wo.diff then
    vim.cmd.normal({ "]c", bang = true })
  else
    gs.nav_hunk("next")
  end
end, "Next Hunk")
map("n", "[h", function()
  if vim.wo.diff then
    vim.cmd.normal({ "[c", bang = true })
  else
    gs.nav_hunk("prev")
  end
end, "Prev Hunk")
map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
map("n", "<leader>ghd", gs.diffthis, "Diff This")
map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
```

The trade-off with this approach is a less detailed history, showing only the most recent changes made by Aider. If you want to maintain a comprehensive history, consider using the advanced Git mode.

#### Advanced Git Workflow (Auto-commits) 🧑‍💻

This workflow deepens Aider-Git integration by utilizing Aider's default commit settings. Aider creates a Git commit for each modification, including the prompts used. This provides a complete history of Aider's changes and enables effective management using Git tools. Recommended for advanced users, this approach requires familiarity with various `git reset` commands. Experimenting with this workflow on a feature branch is highly recommended.

#### Visualizing Changes with Auto-commits 🔍

With auto-commits, use the `after_update_hook` to view the diff of Aider's last change or the complete history of changes:

```lua
-- Using diffview to show the diff of the last change made by Aider:
after_update_hook = function()
  vim.cmd("DiffviewOpen HEAD^")
end

-- Using diffview to show the entire history of changes made by Aider:
after_update_hook = function()
  vim.cmd("DiffviewFileHistory")
end

-- Using telescope to show the entire history of changes made by Aider:
after_update_hook = function()
  vim.cmd("Telescope git_commits")
end
```

`diffview` offers a visual way to review changes. `Telescope` can also be customized with the `delta` pager for improved diff previews. In `diffview`, the `actions.restore_entry` mapping enables local restoration of files to previous states. After restoring, use `gitsigns` to accept hunks or preview specific hunk diffs from the last Aider commit.

By default, selecting a commit in `Telescope` performs a `git checkout <commit>`. Use `git branch -f <branch> HEAD` to move your branch's HEAD to that commit, effectively undoing Aider's last change. `Telescope` also supports custom actions for more advanced Git operations. For instance, create a custom action for a `git reset --soft` on the selected commit, enabling further modification of Aider's changes while keeping a more concise history. With `git reset --soft`, `gitsigns` helps in reverting hunks/files or previewing specific hunk diffs. Refer to [these](https://github.com/aweis89/dotfiles/blob/main/.config/nvim/lua/plugins/telescope.lua) Telescope customizations for examples of custom actions and `delta` pager integration for enhanced diffs.

While `gitsigns` is useful for post-revert hunk management, it can also be used directly with `Gitsigns change_base HEAD^`. This makes the `gitsigns` mappings operate on the last Aider commit instead of uncommitted changes.

#### Useful Keybindings for Advanced Git Workflow 🧑‍💻

These keybindings enable quick access to: the diff of Aider's last change (`<leader>dvh`), the diff of all uncommitted changes (`<leader>dvo`), closing `Diffview` (`<leader>dvc`), and using `Gitsigns` on the last Aider commit (`<leader>ghh`).

```lua
-- View the diff of the last change made by Aider
vim.keymap.set("n", "<leader>dvh", ":DiffviewOpen HEAD^<CR>", { desc = "Diffview HEAD^" })

-- View the diff of all uncommitted changes
vim.keymap.set("n", "<leader>dvo", ":DiffviewOpen<CR>", { desc = "Diffview" })

-- Close Diffview
vim.keymap.set("n", "<leader>dvc", ":DiffviewClose!<CR>", { desc = "Diffview close" })

-- Use Gitsigns to operate on the last Aider commit
vim.keymap.set("n", "<leader>ghh", ":Gitsigns change_base HEAD^<CR>", { desc = "Gitsigns pick reversals" })
```

## 🪪 License

MIT
