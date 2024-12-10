package = "aider-nvim-tests"
version = "0.1.0-1"

source = {
    url = "git://github.com/your-repo/aider-nvim"
}

dependencies = {
    "lua >= 5.1",
    "luassert >= 1.8.0",
    "luv >= 1.44.2",
    "busted >= 2.1.1"
}

build = {
    type = "builtin",
    modules = {
        ['aider.terminal_spec'] = "lua/aider/terminal_spec.lua"
    }
}
