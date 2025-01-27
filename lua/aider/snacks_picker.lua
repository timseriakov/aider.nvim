M = {}

---@param selected snacks.picker.Item[]
local function selected_files(selected)
  local files = {}
  for _, s in ipairs(selected) do
    table.insert(files, s.file)
  end
  return files
end

---@param opts snacks.picker.Config
---@type snacks.picker.finder
function M.git_stash(opts, ctx)
  local args = { "stash", "list" }
  return require("snacks.picker.source.proc").proc({
    opts,
    {
      cmd = "git",
      args = args,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        local stash = item.text:match("^stash@{(%d+)}")
        item.stash = stash
      end,
    },
  }, ctx)
end

function M.aider_changes()
  local ok, picker = pcall(require, "snacks.picker")
  if not ok then
    return nil
  end
  return picker("git_stash", {
    title = "Git Stash",
    finder = M.git_stash,
    format = function(item, picker)
      local message = item.text:match("^stash@{%d+}: %s*(.+)$")
      return { { string.format("#%d", item.stash + 1), "Function" }, { " " .. message, "Comment" } }
    end,
    preview = function(ctx)
      local stash = ctx.item.stash
      local cmd = {
        "git",
        "-c",
        "delta." .. vim.o.background .. "=true",
        "diff",
        string.format("stash@{%d}..stash@{%d}", stash, stash + 1),
      }
      local native = ctx.picker.opts.previewers.git.native
      if not native then
        table.insert(cmd, 2, "--no-pager")
      end
      local exec = Snacks.picker.preview.cmd
      exec(cmd, ctx, { ft = not native and "git" or nil })
      ctx.preview:show(ctx.picker)
      return false
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
