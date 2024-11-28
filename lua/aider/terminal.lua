local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
    buf = nil,
    job_id = nil,
}

---Load files into aider session
---@param selected table Selected files or paths
---@param opts table|nil Additional options
function M.load_in_aider(selected, opts)
    local cleaned_paths = {}
    for _, entry in ipairs(selected) do
        local file_info = path.entry_to_file(entry, opts)
        table.insert(cleaned_paths, file_info.path)
    end
    local paths = table.concat(cleaned_paths, " ")

    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
        local paths_to_add = "/add " .. paths
        vim.fn.chansend(M.job_id, paths_to_add .. "\n")
        vim.api.nvim_input("A")
        return
    end

    local env_args = vim.env.AIDER_ARGS or ""
    local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""
    local command = string.format("aider %s %s%s %s",
        env_args,
        config.values.aider_args,
        dark_mode,
        paths)

    vim.api.nvim_command("vnew")
    M.job_id = vim.fn.termopen(command, {
        on_exit = function()
            vim.cmd("bd!")
        end,
    })
    M.buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_input("A")
end

---Toggle the aider terminal window
function M.toggle()
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
        local wins = vim.fn.win_findbuf(M.buf)

        if #wins > 0 then
            for _, win in ipairs(wins) do
                vim.api.nvim_win_close(win, false)
            end
        else
            vim.cmd("vnew")
            vim.api.nvim_win_set_buf(0, M.buf)
            vim.api.nvim_input("A")
        end
    else
        M.load_in_aider({})
    end
end

---Send a question to aider
---@param prompt string The question to ask
---@param selection string|nil Optional code selection
function M.ask(prompt, selection)
    if not prompt or #vim.trim(prompt) == 0 then
        vim.notify("No input provided", vim.log.levels.WARN)
        return
    end

    local filetype = vim.bo.filetype
    local command
    if selection then
        command = string.format("{%s\n/ask %s%s\n%s}", filetype, prompt, selection, filetype)
    else
        command = string.format("{%s\n/ask %s\n%s}", filetype, prompt, filetype)
    end

    M.load_in_aider({})
    vim.fn.chansend(M.job_id, command .. "\n")
end

return M
