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

Aider says to get the most out of Aider, you should get comfortable using git. Git is the primary tool for managing and viewing changes made by aider. Luckily Neovim has lots of great tools for working with git, including my top 3 favorite diffview, gitsigns, and telescope. To get the most out of this plugin, getting familiar with those tools and using them with Aider.nvim will transform your Aider experience.

### Recipes mappings (simple git mode)

If you're not yet comfortable utilizing git concepts like `git reset` you can still get quite a bit of benefit by using `--no-auto-commits` (e.x. using `aider_args` or the `~/.aider.conf.yml` config file) to simplify the git actions you'd need to take to manage it's changes. When using this mode, this is some useful mappings and tips:

#### Auto show diffs after Aider updates without auto-commit

```lua
-- Using the diffview plugin, show diff:
after_update_hook = function()
  vim.cmd("DiffviewOpen")
end

-- Using telelscope, show diffs
after_update_hook = function()
  vim.cmd("Telescope git_status")
end
```

In both cases, you'll see the diffs that will include changes made by Aider (in addition to any other uncommited changes you've made)
after Aider makes any file changes. After using those integration points to view the diffs, you can just commit and push to accept everything. Or you should use gitsigns if you want to accept, reject or view individual hunks. Gitsigns can also be used to restore entire files. These are useful mappings for working with Aider and gitsigns:

```lua

-- E.x. useful gitsigns mappings taken from LazyVim
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

The downside of this approach is that you won't have a nice history of changes made by Aider to view, only the last changes made. If you want to keep a history of changes made by Aider, you can use the advanced git mode.

#### Advanced git mode

This approach will enabled more integration from Aider with git by allowing it to use the default commit settings, thereby creating a git commit for each change made (including the comment prompts!). This will allow you to see the entire history of changes made by Aider and to use git tooling to manage all those changes. This is the recommended approach for advanced users but also requires getting comfortable with doing different types of `git reset` commands (using a feature branch is a great to get comfortable using this approach).

#### Auto show diffs after Aider updates with auto-commit

```lua
-- Using the diffview plugin, show the last diff:
after_update_hook = function()
  vim.cmd("DiffviewOpen HEAD^")
end

-- Or show the entire history of changes made by Aider:
after_update_hook = function()
  vim.cmd("DiffviewFileHistory")
end

-- Using telescope, show the entire history of changes made by Aider:
after_update_hook = function()
  vim.cmd("Telescope git_commits")
end
```

Using diffview, is more visual (although you can customize to Telescope to use `delta` pager for nicer diff previews). When using diffview, checkout the `actions.restore_entry` mapping to restore files to a previous state locally. After restoring gitsigns can be useful if you want to accept individual hunks or preview specific hunk diffs made by the previous Aider commit.

By default when selecting a commit in telescope, it will just do a `git checkout <commit>`, you can then do a `git branch -f <branch> HEAD` to change the HEAD of your branch to that commit, effectively reversing Aider's last change. However Telescope also makes it easy to create custom actions to do more advanced git operations. Personally I like to do a `git reset --soft` on the selected commit if I want to make some changes on top of Aider's changes. That will reverse Aider's commits but keep it's changes in your working files for further modifications, leading to a more compact history. When doing this, gitsigns is also useful if you want to revert individual hunks or files or preview specific hunk diffs. Checkout [these](https://github.com/aweis89/dotfiles/blob/main/.config/nvim/lua/plugins/telescope.lua) telescope customizations for examples on creating those custom actions and integrating with `delta` pager for nicer diffs.

Note, while gitigns can be useful for working with hunks after reverting Aider's changes using the above techniques, you can also use it directly by running `Gitsigns change_base HEAD^`. Then all the mappings from the previous section will work as expected only to revert/inspect the last applied Aider commit rather than uncommited changes.

```lua

## 🪪 License

MIT
```
