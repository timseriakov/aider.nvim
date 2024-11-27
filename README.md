# nvim-aider

A Neovim plugin for seamless integration with [Aider](https://github.com/paul-gauthier/aider), an AI pair programming tool.

## Features

- Toggle Aider terminal window
- Load files into Aider session
- Ask questions about code with visual selection support
- Integration with fzf-lua for file selection
- Maintains persistent Aider sessions

## Prerequisites

- Neovim 0.5+
- [Aider](https://github.com/paul-gauthier/aider) installed (`pip install aider-chat`)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) (optional, for enhanced file selection)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "mattkubej/nvim-aider",
    dependencies = {
        "ibhagwan/fzf-lua", -- optional
    },
    config = function()
        require("aider").setup()
    end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    'mattkubej/nvim-aider',
    requires = { 'ibhagwan/fzf-lua' }, -- optional
    config = function()
        require('aider').setup()
    end
}
```

## Commands

- `:AiderToggle` - Toggle the Aider terminal window
- `:AiderLoad [files...]` - Load files into Aider session
- `:AiderAsk` - Ask a question about code (works in visual mode)

## Default Keymaps

The plugin doesn't set any default keymaps. Here's an example of how you might want to set them up:

```lua
vim.keymap.set('n', '<leader>at', '<cmd>AiderToggle<CR>', { desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>al', '<cmd>AiderLoad<CR>', { desc = 'Load current file in Aider' })
vim.keymap.set('n', '<leader>aa', '<cmd>AiderAsk<CR>', { desc = 'Ask Aider about code' })
vim.keymap.set('v', '<leader>aa', '<cmd>AiderAsk<CR>', { desc = 'Ask Aider about selection' })
```

## FZF-lua Integration

When fzf-lua is installed, you can use `Ctrl-l` in the file picker to load files into Aider:

- Single file: Navigate to a file and press `Ctrl-l` to load it into Aider
- Multiple files: Use `Shift-Tab` to select multiple files, then press `Ctrl-l` to load all selected files
- The files will be automatically added to your current Aider session if one exists, or start a new session if none is active

## Configuration

The plugin can be configured during setup:

```lua
require('aider').setup({
    -- Configuration options will be added in future releases
})
```

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
