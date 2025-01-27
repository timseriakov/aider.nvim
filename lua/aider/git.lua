local M = {}

local function untrackedFiles()
  local files = {}
  local command = { "git", "ls-files", "--others", "--exclude-standard" }
  local job = vim.system(command, {
    stdout = function(_, data)
      -- 'data' will be a single line of output each time
      if data ~= nil and #data > 0 then
        table.insert(files, data)
      end
    end,
    stderr = function(_, err)
      if err and #err > 0 then
        vim.notify("git error: " .. err, vim.log.levels.ERROR)
      end
    end,
  })

  -- Wait for the process to finish, then return the table
  local exit_code = job:wait()
  if exit_code ~= 0 then
    vim.notify(
      ("'git ls-files' exited with code %d"):format(exit_code),
      vim.log.levels.ERROR
    )
  end

  return files
end

local function getLatestStashHash()
  local cmd = { "git", "rev-parse", "-q", "--verify", "refs/stash" }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code == 0 then
    return vim.trim(result.stdout)
  end
  return nil
end

---@param message string
---@param path table|nil
function M.stash(message)
  if path then
    -- in-case file is untracked, make it tracked (without staging it)
    local track_cmd = { "git", "add", "--intent-to-add" }
    for _, path in ipairs(untrackedFiles()) do
      table.insert(track_cmd, path)
    end
    vim.system(track_cmd):wait()
  end

  local create_cmd = { "git", "stash", "create" }
  vim.system(create_cmd, { text = true }, function(out)
    if out.code ~= 0 then
      vim.notify("Failed to stash changes:\n" .. out.stderr, vim.log.levels.ERROR)
      return
    end
    local hash = vim.trim(out.stdout or "")
    if #hash == 0 then
      vim.notify("No tracked changes to stash", vim.log.levels.ERROR)
      return
    end

    -- Compare with previous stash
    local latest_stash = getLatestStashHash()
    if latest_stash and latest_stash == hash then
      vim.notify("No new changes to stash", vim.log.levels.INFO)
      return
    end

    local store_cmd = { "git", "stash", "store", "-m", message, hash }
    vim.system(store_cmd, { text = true }, function(store_out)
      if store_out.code ~= 0 then
        vim.notify("Failed to stash changes " .. hash .. ":\n" .. store_out.stderr, vim.log.levels.ERROR)
        return
      end
    end)
  end)
end

return M
