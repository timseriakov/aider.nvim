# aider.nvim

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

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
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced file selection)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    { "willothy/flatten.nvim", config = true }, -- required for /editor command functionality
    {
        "aweis89/aider.nvim",
        dependencies = {
            "ibhagwan/fzf-lua", -- or "nvim-telescope/telescope.nvim"
            "willothy/flatten.nvim", -- required for /editor command functionality
        },
        init = function()
          require("aider").setup()
        end,
        -- e.x. mappings
        keys = {
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
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
" Choose one of:
Plug 'ibhagwan/fzf-lua'
" or
Plug 'nvim-telescope/telescope.nvim'

Plug 'willothy/flatten.nvim'
Plug 'aweis89/aider.nvim'

" After plug#end(), add the setup and mappings:
lua << EOF
require('flatten').setup()
require('aider').setup()

vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
EOF
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'aweis89/aider.nvim',
    requires = {
        -- Choose one of:
        'ibhagwan/fzf-lua',
        -- or
        'nvim-telescope/telescope.nvim',
        
        'willothy/flatten.nvim'
    },
    config = function()
        require('flatten').setup()
        require('aider').setup()
        
        vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider' })
        vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
        vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
    end
}
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
" Choose one of:
call dein#add('ibhagwan/fzf-lua')
" or
call dein#add('nvim-telescope/telescope.nvim')

call dein#add('willothy/flatten.nvim')
call dein#add('aweis89/aider.nvim')

" After loading plugins, add the setup and mappings:
lua << EOF
require('flatten').setup()
require('aider').setup()

vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
EOF
```

### Using [Vundle.vim](https://github.com/VundleVim/Vundle.vim)

```vim
" Choose one of:
Plugin 'ibhagwan/fzf-lua'
" or
Plugin 'nvim-telescope/telescope.nvim'

Plugin 'willothy/flatten.nvim'
Plugin 'aweis89/aider.nvim'

" After Plugin commands, add the setup and mappings:
lua << EOF
require('flatten').setup()
require('aider').setup()

vim.keymap.set('n', '<leader>a<space>', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Add file to aider' })
vim.keymap.set({ 'n', 'v' }, '<leader>ad', '<cmd>AiderAsk<CR>', { desc = 'Ask with selection' })
EOF
```

## Commands

- `:AiderToggle` - Toggle the Aider terminal window
- `:AiderLoad [files...]` - Load files into Aider session
- `:AiderAsk [prompt]` - Ask a question about code using the /ask command. If no prompt is provided, it will open an input popup. In visual mode, the selected text is appended to the prompt.
- `:AiderSend [command]` - Send any command to Aider. In visual mode, the selected text is appended to the command.

Example commands for common prompts:

```vim
" In your vimrc/init.vim:
command! -range AiderExplain <line1>,<line2>AiderSend /ask Explain this code
command! -range AiderOptimize <line1>,<line2>AiderSend Please optimize this code for performance
command! -range AiderTest <line1>,<line2>AiderSend Please write tests for this code
command! -range AiderDoc <line1>,<line2>AiderSend Please add documentation for this code
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
        layout = "float",     -- 'float', 'vertical', 'horizontal', or 'current'
        width = 0.9,         -- width of the window (in columns or percentage)
        height = 0.9,        -- height of the window (in lines or percentage)
        border = "rounded",   -- 'none', 'single', 'double', 'rounded', etc.
    }
})
```

### Dark Mode

The plugin automatically sets the `--dark-mode` flag when Neovim's `background` option is set to "dark". This ensures aider's UI matches your Neovim theme.

### Environment Variables

- `AIDER_ARGS`: Set default command line arguments for aider. These are applied before any arguments specified in the plugin configuration.
- `AIDER_EDITOR`: Set by the plugin when using tmux (see Editor Command below).

### Editor Command Behavior

The plugin uses flatten.nvim to handle the `/editor` command, which allows for proper nested Neovim sessions. When you use the `/editor` command in Aider, it will open a new buffer in a popup window. The plugin remaps `wq` in this buffer to write the file and return to your Aider session seamlessly.

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

## License

MIT
