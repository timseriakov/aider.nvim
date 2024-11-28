local M = {}

---Setup aider plugin
---@param opts table|nil Configuration options
function M.setup(opts)
    require("aider.config").setup(opts)
    require("aider.commands").setup()
end

return M
