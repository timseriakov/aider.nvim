# 🤝 aider.nvim

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

## ✨ Features

- When using the `--watch-file` [feature](https://aider.chat/docs/config/options.html#--watch-files) (default)
  - Aider will automatically startup when valid [comments](https://aider.chat/docs/config/options.html#--watch-files) are written
  - Aider will auto-detect `ai`, `ai!` and `ai?` [comments](https://aider.chat/docs/config/options.html#--watch-files)
  - When comment is a question (`ai?`) aider will automatically show the terminal
  - All files with AI comments will get added to aider automatically
- Get live streamed notifications as Aider is processing ⚡️
- The terminal will automatically be brought to the foreground if Aider prompts for input 💬
- Auto reload all files changed by Aider 🔄
- Add configurable hooks to run when Aider finishes updating a file 🪝
  - For example, you can use [diffview](https://github.com/sindrets/diffview.nvim) to always show a gorgeous diff
- Send commands to Aider explicitly with `AiderSend <cmd>` প্রেরণ
  - Can be used to create custom prompts
- Toggle Aider terminal window and bring to background/foreground at any time, with multiple window formats 💻
- Load files into Aider session
  - You can use fzf-lua or telescope to select files (multi-select supported) with multiple file viewers:
    - For Telescope the custom action as been added to `git_files`, `find_files`, `buffers` and `oldfiles`
    - For fzf-lua any file finder that follows standard conventions for passing file params
  - When not it watch mode `AiderLoad` without args can be used to `/add` the current file, or specify file args
- Ask questions about code with visual selection support ❓
  - `AiderAsk` with a visual selection will prompt you for input and add the selected code to the prompt
- For diff viewing, accepting or rejecting changes:
  - Use [diffview](https://github.com/sindrets/diffview.nvim) which can auto trigger after Aider makes changes (see below).
  - Use [gitsigns](https://github.com/lewis6991/gitsigns.nvim) to stage/view/undo/navigate hunks
- Supports switching to different repos and will maintain context per repo 🔀
- Telescope picker for selecting models `:Telescope model_picker`
  - Use `model_picker_search = { "^anthropic/", "^openai/" }` to specify which models to look for
- Integration with tokyonight and catppuccin themes 🌈

## 🛠️ Prerequisites

- Neovim 0.5+
- [Aider](https://github.com/paul-gauthier/aider) required bo to be installed and available in `PATH` (`pip install aider-chat`)
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) is required for terminal management
- [diffview](https://github.com/sindrets/diffview.nvim)is optional but it is a great way to view Aider's changes, revert or undo them, see integration below
- [snacks](https://github.com/folke/snacks.nvim) is optional but will show spinner whenever aider is active
- [fidget](https://github.com/j-hui/fidget.nvim) is optional but it will show aider log notifications in a none-intrusive way
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced file selection)
- [willothy/flatten.nvim](https://github.com/willothy/flatten.nvim) (only if you want to use `/editor` command)

## 📦 Installation

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
      "folke/snacks.nvim"

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

      -- Optional but will show aider spinner whenever active
      "folke/snacks.nvim"

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
vim.keymap.set('n', '<leader>au', '<cmd>AiderSend /undo<CR>', { noremap = true, silent = true, desc = 'Aider undo' })
vim.keymap.set({ 'i', 't', 'n' }, '<C-x>', '<cmd>AiderToggle<CR>', { noremap = true, silent = true, desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { noremap = true, silent = true, desc = 'Add file to aider' })
vim.keymap.set({ 'v', 'n' }, '<leader>ad', '<cmd>AiderAsk<CR>', { noremap = true, silent = true, desc = 'Ask with selection' })
vim.keymap.set('n', '<leader>ams', '<cmd>AiderSend /model sonnet<CR>', { noremap = true, silent = true, desc = 'Switch to sonnet' })
vim.keymap.set('n', '<leader>amh', '<cmd>AiderSend /model haiku<CR>', { noremap = true, silent = true, desc = 'Switch to haiku' })
EOF
call plug#end()
```

## ⌨️ Commands

- `:AiderToggle [direction]` - Toggle the Aider terminal window. Optional direction can be:
  - `vertical` - Switch to vertical split ↔️
  - `horizontal` - Switch to horizontal split ↕️
  - `float` - Switch to floating window (default) 🪟
  - `tab` - Switch to new tab 📑
  - When called without a direction argument, it opens in the to the last specified direction (or the toggleterm specified default). With a direction argument, it will switch the terminal to that layout (even if already open).
- `:AiderLoad [files...]` - Load files into Aider session, defaults to the current file when no args are specified 📂
- `:AiderAsk [prompt]` - Ask a question about code using the /ask command. If no prompt is provided, it will open an input popup. In visual mode, the selected text is appended to the prompt. 🙋
- `:AiderSend [command]` - Send any command to Aider. In visual mode, the selected text is appended to the command. 📨

## 🤝 FZF-lua Integration

When fzf-lua is installed, you can use `Ctrl-l` in the file picker to load files into Aider:

- Single file: Navigate to a file and press `Ctrl-l` to load it into Aider
- Multiple files: Use `Shift-Tab` to select multiple files, then press `Ctrl-l` to load all selected files
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground
- FZF also support a select-all behavior, which can be used to load all files matching a suffix for example

## 🔭 Telescope Integration

When Telescope is installed, you can use `<C-l>` load files into Aider:

- Current pickers with this registered action include: find_files, git_files, buffers and oldfiles
- Single file: Navigate to a file and press `<C-l>` to load it into Aider.
- Multiple files: Use multi-select to choose files (default <tab>), then press `<C-l>` to load all selected files.
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active.
  - If `watch_mode` is set (as per the default), the file will be added in the background, otherwise Aider will be brought to the foreground

## ⚙️ Configuration

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
  style = "compact",
  -- * compact: use border for icon and title
  -- * minimal: no border, only icon and message
  -- * fancy: similar to the default nvim-notify style
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

 -- git pager to use, defaults to 'cat' to prevent blocking after_update_hook
 git_pager = "cat",
})
```

## Git Tips & Integration

### Philosophy

To get the most out of `aider.nvim`, it's essential to use Git effectively. Git is the primary tool for managing and viewing changes made by Aider. Fortunately, Neovim offers excellent tools for Git integration, including `diffview`, `gitsigns`, and `telescope`. Familiarizing yourself with these tools and using them alongside `aider.nvim` will significantly enhance your Aider experience.

### Simple Git Mode (Using `--no-auto-commits`)

If you're not yet comfortable with advanced Git concepts like `git reset`, you can still benefit from a simplified workflow by using the `--no-auto-commits` option. You can set this option via `aider_args` in your `aider.nvim` configuration or in the `~/.aider.conf.yml` file. This approach simplifies the Git actions needed to manage Aider's changes.

#### Viewing Diffs Without Auto-commits

In this mode, Aider won't automatically commit changes. Instead, it will leave the changes uncommitted in your working directory. You can then use the `after_update_hook` to view the diffs using either `diffview` or `telescope`:

```lua
-- Using diffview to show the diff:
after_update_hook = function()
  vim.cmd("DiffviewOpen")
end

-- Using telescope to show the diffs:
after_update_hook = function()
  vim.cmd("Telescope git_status")
end
```

These hooks will display the diffs containing changes made by Aider, along with any other uncommitted changes in your working directory. After reviewing the diffs, you can commit everything to accept the changes or use `gitsigns` to selectively stage, unstage, or revert individual hunks or entire files.

#### Useful `gitsigns` Mappings

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

The downside of this approach is that you won't have a detailed history of changes made by Aider, only the most recent changes. If you want to maintain a comprehensive history, consider using the advanced Git mode.

#### Advanced Git Mode (Using Auto-commits)

This approach enables deeper integration between Aider and Git by allowing Aider to use its default commit settings. Aider will create a Git commit for each change it makes, including the prompts you use. This allows you to see the entire history of changes made by Aider and use Git tools to manage those changes effectively. This is the recommended approach for advanced users but requires familiarity with different types of `git reset` commands. Using a feature branch is a great way to experiment with this approach.

#### Viewing Diffs with Auto-commits

With auto-commits enabled, you can use the `after_update_hook` to view the diff of the last change made by Aider or the entire history of changes:

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

`diffview` provides a more visual way to review changes, although you can customize `telescope` to use the `delta` pager for enhanced diff previews. When using `diffview`, the `actions.restore_entry` mapping allows you to restore files to a previous state locally. After restoring, you can use `gitsigns` to accept individual hunks or preview specific hunk diffs from the previous Aider commit.

By default, selecting a commit in `telescope` will perform a `git checkout <commit>`. You can then use `git branch -f <branch> HEAD` to move the HEAD of your branch to that commit, effectively reversing Aider's last change. However, `telescope` also allows you to create custom actions for more advanced Git operations. For example, you could create an action to perform a `git reset --soft` on the selected commit, allowing you to modify Aider's changes further while maintaining a more compact history. When using `git reset --soft`, `gitsigns` can be helpful for reverting individual hunks or files or previewing specific hunk diffs. Check out [these](https://github.com/aweis89/dotfiles/blob/main/.config/nvim/lua/plugins/telescope.lua) telescope customizations for examples of creating custom actions and integrating with the `delta` pager for improved diffs.

Note that while `gitsigns` is useful for working with hunks after reverting Aider's changes, you can also use it directly by running `Gitsigns change_base HEAD^`. This will make the `gitsigns` mappings from the previous section operate on the last Aider commit instead of uncommitted changes.

## 🪪 License

MIT
```