# aider.nvim

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

> ⚠️ **Warning**: This plugin is under rapid development and breaking changes may occur. If you encounter any issues, please [file an issue](https://github.com/aweis89/aider.nvim/issues) on GitHub.

## Features

- Toggle Aider terminal window
- Load files into Aider session
- Ask questions about code with visual selection support
- Integration with fzf-lua and Telescope for file selection
- Maintains persistent Aider sessions

## Prerequisites

- Neovim 0.5+
- [Aider](https://github.com/paul-gauthier/aider) installed (`pip install aider-chat`)
- [willothy/flatten.nvim](https://github.com/willothy/flatten.nvim) (required for `/editor` command functionality)
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) (required for terminal management)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced file selection)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  { "willothy/flatten.nvim", config = true },
  {
    "akinsho/toggleterm.nvim",
    opts = {
      shade_terminals = false,
      direction = "float", -- default direction when none specified in AiderToggle
      float_opts = {
        border = "curved",
        title_pos = "center",
      },
      close_on_exit = true,
      size = function(term)
        if term.direction == "horizontal" then
          return vim.o.lines * 0.4  -- 40% height
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4  -- 40% width
        end
      end,
    },
  },
  {
    "aweis89/aider.nvim",
    dependencies = {
      "akinsho/toggleterm.nvim",
      "ibhagwan/fzf-lua", -- or "nvim-telescope/telescope.nvim"
      "willothy/flatten.nvim",
    },
    config = true,
    keys = {
      {
        "<leader>a<space>",
        "<cmd>AiderToggle<CR>",
        desc = "Toggle Aider (default)",
      },
      {
        "<leader>av",
        "<cmd>AiderToggle vertical<CR>",
        desc = "Toggle Aider vertical split",
      },
      {
        "<leader>ah",
        "<cmd>AiderToggle horizontal<CR>",
        desc = "Toggle Aider horizontal split",
      },
      {
        "<leader>af",
        "<cmd>AiderToggle float<CR>",
        desc = "Toggle Aider floating window",
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

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'willothy/flatten.nvim'
Plug 'akinsho/toggleterm.nvim'
" Choose one of:
Plug 'ibhagwan/fzf-lua'
" or
Plug 'nvim-telescope/telescope.nvim'
Plug 'aweis89/aider.nvim'

" After plug#end(), add the setup:
lua << EOF
require('flatten').setup()
require('toggleterm').setup({
  shade_terminals = false,
  direction = "float",
  float_opts = {
    border = "curved",
    title_pos = "center",
  },
  close_on_exit = true,
  size = function(term)
    if term.direction == "horizontal" then
      return vim.o.lines * 0.4
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
})
require('aider').setup()

" Key mappings
vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider (default)' })
vim.keymap.set('n', '<leader>av', '<cmd>AiderToggle vertical<CR>', { desc = 'Toggle Aider vertical split' })
vim.keymap.set('n', '<leader>ah', '<cmd>AiderToggle horizontal<CR>', { desc = 'Toggle Aider horizontal split' })
vim.keymap.set('n', '<leader>af', '<cmd>AiderToggle float<CR>', { desc = 'Toggle Aider floating window' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
EOF
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "willothy/flatten.nvim", config = true }
use {
  "akinsho/toggleterm.nvim",
  config = function()
    require("toggleterm").setup({
      shade_terminals = false,
      direction = "float",
      float_opts = {
        border = "curved",
        title_pos = "center",
      },
      close_on_exit = true,
      size = function(term)
        if term.direction == "horizontal" then
          return vim.o.lines * 0.4
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    })
  end
}
use {
  "aweis89/aider.nvim",
  requires = {
    "akinsho/toggleterm.nvim",
    -- Choose one of:
    "ibhagwan/fzf-lua",
    -- or
    "nvim-telescope/telescope.nvim",
    "willothy/flatten.nvim",
  },
  config = function()
    require("aider").setup()
  end,
  keys = {
    { "<leader>a<space>", "<cmd>AiderToggle<CR>", desc = "Toggle Aider (default)" },
    { "<leader>av", "<cmd>AiderToggle vertical<CR>", desc = "Toggle Aider vertical split" },
    { "<leader>ah", "<cmd>AiderToggle horizontal<CR>", desc = "Toggle Aider horizontal split" },
    { "<leader>af", "<cmd>AiderToggle float<CR>", desc = "Toggle Aider floating window" },
    { "<leader>al", "<cmd>AiderLoad<CR>", desc = "Add file to aider" },
    { "<leader>ad", "<cmd>AiderAsk<CR>", desc = "Ask with selection", mode = { "v", "n" } },
  },
}
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('willothy/flatten.nvim')
call dein#add('akinsho/toggleterm.nvim')
" Choose one of:
call dein#add('ibhagwan/fzf-lua')
" or
call dein#add('nvim-telescope/telescope.nvim')
call dein#add('aweis89/aider.nvim')

" After loading plugins, add the setup:
lua << EOF
require('flatten').setup()
require('toggleterm').setup({
  shade_terminals = false,
  direction = "float",
  float_opts = {
    border = "curved",
    title_pos = "center",
  },
  close_on_exit = true,
  size = function(term)
    if term.direction == "horizontal" then
      return vim.o.lines * 0.4
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
})
require('aider').setup()

" Key mappings
vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider (default)' })
vim.keymap.set('n', '<leader>av', '<cmd>AiderToggle vertical<CR>', { desc = 'Toggle Aider vertical split' })
vim.keymap.set('n', '<leader>ah', '<cmd>AiderToggle horizontal<CR>', { desc = 'Toggle Aider horizontal split' })
vim.keymap.set('n', '<leader>af', '<cmd>AiderToggle float<CR>', { desc = 'Toggle Aider floating window' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
EOF
```

### Using [Vundle.vim](https://github.com/VundleVim/Vundle.vim)

```vim
Plugin 'willothy/flatten.nvim'
Plugin 'akinsho/toggleterm.nvim'
" Choose one of:
Plugin 'ibhagwan/fzf-lua'
" or
Plugin 'nvim-telescope/telescope.nvim'
Plugin 'aweis89/aider.nvim'

" After Plugin commands, add the setup:
lua << EOF
require('flatten').setup()
require('toggleterm').setup({
  shade_terminals = false,
  direction = "float",
  float_opts = {
    border = "curved",
    title_pos = "center",
  },
  close_on_exit = true,
  size = function(term)
    if term.direction == "horizontal" then
      return vim.o.lines * 0.4
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
})
require('aider').setup()

" Key mappings
vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider (default)' })
vim.keymap.set('n', '<leader>av', '<cmd>AiderToggle vertical<CR>', { desc = 'Toggle Aider vertical split' })
vim.keymap.set('n', '<leader>ah', '<cmd>AiderToggle horizontal<CR>', { desc = 'Toggle Aider horizontal split' })
vim.keymap.set('n', '<leader>af', '<cmd>AiderToggle float<CR>', { desc = 'Toggle Aider floating window' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
EOF
```

## Commands

- `:AiderToggle [direction]` - Toggle the Aider terminal window. Optional direction can be:
  - `vertical` - Switch to vertical split
  - `horizontal` - Switch to horizontal split
  - `float` - Switch to floating window (default)
  - `tab` - Switch to new tab
  - When called without a direction argument, it opens in the to the last specified direction (or the toggleterm specified default). With a direction argument, will switch the terminal to that layout (even if already open).

- `:AiderLoad [files...]` - Load files into Aider session
- `:AiderAsk [prompt]` - Ask a question about code using the /ask command. If no prompt is provided, it will open an input popup. In visual mode, the selected text is appended to the prompt.
- `:AiderSend [command]` - Send any command to Aider. In visual mode, the selected text is appended to the command.

Example commands for common prompts:

```vim
" In your vimrc/init.vim:
command! -range AiderExplain execute "normal! '<,'>AiderSend /ask Explain this code"
command! -range AiderOptimize execute "normal! '<,'>AiderSend Please optimize this code for performance"
command! -range AiderTest execute "normal! '<,'>AiderSend Please write tests for this code"
command! -range AiderDoc execute "normal! '<,'>AiderSend Please add documentation for this code"
```

Or using Lua in your init.lua:

```lua
-- Create user commands for common Aider interactions
local aider_commands = {
  AiderExplain = "/ask Explain this code",
  AiderOptimize = "Please optimize this code for performance",
  AiderTest = "Please write tests for this code",
  AiderDoc = "Please add documentation for this code"
}

-- Register all commands
for cmd_name, prompt in pairs(aider_commands) do
  vim.api.nvim_create_user_command(cmd_name,
    string.format([[execute "normal! '<,'>AiderSend %s"]], prompt),
    { range = true }
  )
end
```

These can be used in visual mode like:

- `:AiderExplain` - Get an explanation of the selected code
- `:AiderOptimize` - Request performance optimization
- `:AiderTest` - Generate tests for the selection
- `:AiderDoc` - Add documentation to the selected code

## FZF-lua Integration

When fzf-lua is installed, you can use `Ctrl-l` in the file picker to load files into Aider:

- Single file: Navigate to a file and press `Ctrl-l` to load it into Aider
- Multiple files: Use `Shift-Tab` to select multiple files, then press `Ctrl-l` to load all selected files
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active
- FZF also support a select-all behavior, which can be used to load all files matching a suffix for example

## Telescope Integration

When Telescope is installed, you can use `<C-l>` in any file picker to load files into Aider:

- Single file: Navigate to a file and press `<C-l>` to load it into Aider.
- Multiple files: Use multi-select to choose files, then press `<C-l>` to load all selected files.
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active.

## Configuration

The plugin can be configured during setup:

```lua
require('aider').setup({
    -- Override the default editor command to use tmux popups
    editor_command = 'tmux popup -E nvim',

    -- Change the FZF action key (defaults to 'ctrl-l')
    fzf_action_key = 'ctrl-x',

    -- Change the Telescope action key (defaults to '<C-l>')
    telescope_action_key = '<C-l>',

    -- Set default arguments for aider CLI (can also use AIDER_ARGS env var)
    aider_args = '--model gpt-4 --no-auto-commits',

    -- Configure window display (these are the defaults)
    window = {
        layout = "float",     -- 'float', 'vertical', 'horizontal', 'tab', or 'current'
        width = 0.9,         -- width of the window (in columns or percentage)
        height = 0.9,        -- height of the window (in lines or percentage)
        border = "rounded",   -- 'none', 'single', 'double', 'rounded', etc.
    }
})
```

### Dark Mode

The plugin automatically sets the `--dark-mode` flag when Neovim's `background` option is set to "dark". This ensures aider's UI matches your Neovim theme.

### Editor Command Behavior

The plugin uses flatten.nvim to handle the `/editor` command, which allows for proper nested Neovim sessions. When you use the `/editor` command in Aider, it will open a new buffer to format your prompt. The plugin remaps `wq` in this buffer to write the file and return to your Aider session seamlessly.

You can customize the editor command in your setup if needed. For example, if you prefer using tmux:

```lua
editor_command = "tmux popup -E nvim"
```

The default FZF action key is `ctrl-l`, but this can be customized using the `fzf_action_key` option during setup.

## Usage Examples

1. Toggle Aider window:

```vim
:AiderToggle
```

2. Load current file into Aider:

```vim
:AiderLoad
```

3. Load specific files:

```vim
:AiderLoad path/to/file1.lua path/to/file2.lua
```

4. Ask about code:
   - Select code in visual mode
   - Run `:AiderAsk`
   - Enter your prompt
   - Aider will respond in the terminal window

## Tips

### Terminal mappings

For terminal mappings to take effect in floats, you need to use `TermOpen` autocommand, e.x.:

```lua
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    local function tmap(key, val)
      vim.api.nvim_buf_set_keymap(0, "t", key, val, { noremap = true, silent = true })
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
    -- auto start terminal in insert mode
    vim.cmd("startinsert")
  end,
})
```

## License

MIT
