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
    "aweis89/aider.nvim",
    dependencies = {
        "ibhagwan/fzf-lua",
    },
    init = function()
        require("aider").setup()
    end,
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

## Commands

- `:AiderToggle` - Toggle the Aider terminal window
- `:AiderLoad [files...]` - Load files into Aider session
- `:AiderAsk` - Ask a question about code (works in visual mode)

## Default Keymaps

The plugin comes with the following default keymaps when using lazy.nvim:

- `<leader>a<space>` - Toggle Aider terminal window
- `<leader>al` - Load current file into Aider
- `<leader>ad` - Ask Aider about code (works in both normal and visual mode)

You can customize these keymaps in your lazy.nvim configuration.

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
