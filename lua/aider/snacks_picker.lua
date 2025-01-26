M = {}

---@param selected snacks.picker.Item[]
local function selected_files(selected)
  local files = {}
  for _, s in ipairs(selected) do
    table.insert(files, s.file)
  end
  return files
end

---@param opts AiderConfig
function M.setup(opts)
  local ok, snacks_picker = pcall(require, "snacks.picker")
  if not ok then
    return
  end

  local actions = snacks_picker.actions
  actions.aider_add = function(picker)
    picker:close()
    local files = selected_files(picker:selected({ fallback = true }))
    require("aider.terminal").add(files)
  end

  actions.aider_read_only = function(picker)
    picker:close()
    local files = selected_files(picker:selected({ fallback = true }))
    require("aider.terminal").read_only(files)
  end

  actions.aider_drop = function(picker)
    picker:close()
    local files = selected_files(picker:selected({ fallback = true }))
    require("aider.terminal").drop(files)
  end
end

return M
