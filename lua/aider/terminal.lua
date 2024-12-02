local Terminal = require("toggleterm.terminal").Terminal
local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
    term = nil,
    prev_buf = nil,
}

-- Create Aider terminal instance
local function create_aider_terminal(cmd)
    return Terminal:new({
        cmd = cmd,
        hidden = true,
        on_exit = function()
            M.term = nil
        end,
    })
end

---Load files into aider session
---@param selected table Selected files or paths
---@param opts table|nil Additional options
function M.laod_files_in_aider(selected, opts)
    local cleaned_paths = {}
    for _, entry in ipairs(selected) do
        local file_info = path.entry_to_file(entry, opts)
        table.insert(cleaned_paths, file_info.path)
    end
    local paths = table.concat(cleaned_paths, " ")

    if M.term and M.term:is_open() then
        local add_paths = "/add " .. paths
        M.term:send(add_paths)
        return
    end

    local env_args = vim.env.AIDER_ARGS or ""
    local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""
    local command = string.format("aider %s %s%s %s", env_args, config.values.aider_args, dark_mode, paths)

    M.prev_buf = vim.api.nvim_get_current_buf()
    M.term = create_aider_terminal(command)
    local direction = config.values.toggleterm.direction
    local opts = {
        direction = direction,
    }
    if direction ~= "float" then
        if direction == "horizontal" then
            opts.size = math.floor(vim.o.lines * config.values.toggleterm.size)
        else
            opts.size = math.floor(vim.o.columns * config.values.toggleterm.size)
        end
    end
    if direction == "float" then
        opts.float_opts = config.values.toggleterm.float_opts
    end
    M.term:open(opts)
end

function M.toggle_aider_window()
    if not M.term then
        M.prev_buf = vim.api.nvim_get_current_buf()
        M.laod_files_in_aider({})
        return
    end

    local direction = config.values.toggleterm.direction
    local opts = {
        direction = direction,
    }
    if direction ~= "float" then
        if direction == "horizontal" then
            opts.size = math.floor(vim.o.lines * config.values.toggleterm.size)
        else
            opts.size = math.floor(vim.o.columns * config.values.toggleterm.size)
        end
    end
    if direction == "float" then
        opts.float_opts = config.values.toggleterm.float_opts
    end
    M.term:toggle(opts)
end

function M.send_command_to_aider(command)
    if not M.term then
        M.laod_files_in_aider({})
    end
    M.term:send(command .. "\n")
end

function M.ask_aider(prompt, selection)
    if not prompt or #vim.trim(prompt) == 0 then
        vim.notify("No input provided", vim.log.levels.WARN)
        return
    end

    local command
    if selection then
        prompt = string.format("%s\n%s}", prompt, selection)
    end

    command = "/ask " .. prompt
    M.send_command_to_aider(command)
end

return M
