M = {}

---@param selected snacks.picker.Item[]
local function selected_files(selected)
  local files = {}
  for _, s in ipairs(selected) do
    table.insert(files, s.file)
  end
  return files
end

function M.create_picker()
  local output = vim.system({ "git", "stash", "list" }, { text = true }):wait()
  if output.code ~= 0 then
    vim.notify("Failed to get git stash list", vim.log.levels.ERROR)
    return
  end

  local items = {}
  for line in vim.gsplit(output.stdout, "\n") do
    if line ~= "" then
      table.insert(items, {
        text = line,
        stash = line:match("^stash@{(%d+)}") -- Extract stash index
      })
    end
  end

  Snacks.picker({
    title = "Git Stash",
    finder = function()
      return items
    end,
    format = function(item)
      return { { item.text, "Comment" } }
    end,
    preview = function(ctx)
      if not ctx.item.stash then
        return Snacks.picker.preview.none(ctx)
      end
      local cmd = {
        "git",
        "-c",
        "delta." .. vim.o.background .. "=true",
        "stash",
        "show",
        "-p",
        ctx.item.stash,
      }
      local native = ctx.picker.opts.previewers.git.native
      if not native then
        table.insert(cmd, 2, "--no-pager")
      end
      local exec = Snacks.picker.preview.cmd
      exec(cmd, ctx, { ft = not native and "git" or nil })
      return true
    end,

    actions = {
      apply = {
        function(picker)
          local item = picker:current()
          if item and item.stash then
            picker:close()
            vim.cmd("Git stash apply " .. item.stash)
          end
        end,
        mode = { "n", "i" }
      },
      pop = {
        function(picker)
          local item = picker:current()
          if item and item.stash then
            picker:close()
            vim.cmd("Git stash pop " .. item.stash)
          end
        end,
        mode = { "n", "i" }
      },
      drop = {
        function(picker)
          local item = picker:current()
          if item and item.stash then
            picker:close()
            vim.cmd("Git stash drop " .. item.stash)
          end
        end,
        mode = { "n", "i" }
      }
    }
  })
end

---@param opts AiderConfig
function M.setup(opts)
  -- M.create_picker()
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
