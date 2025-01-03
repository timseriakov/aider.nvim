local M = {}

-- add tests for this function as well ai!
function M.remove_comment_chars(comment)
  return comment:gsub("^%s*([%-%-/%#]+%s*)", "")
end

---@param comments table|nil
---@return table<string, boolean>
function M.comment_matches(comments)
  local matches = {
    any = false,
    ["ai?"] = false,
    ["ai!"] = false,
    ["ai"] = false,
  }

  if not comments then
    return matches
  end

  for _, comment in ipairs(comments) do
    local lowered = comment:lower()

    if lowered:match("^%s*ai%?%s*$") then                                    -- Matches "ai?" exactly or with leading/trailing spaces
      matches["ai?"] = true
    elseif lowered:match("^%s*ai!%s*$") then                                 -- Matches "ai!" exactly or with leading/trailing spaces
      matches["ai!"] = true
    elseif lowered:match("^%s*ai%s*$") then                                  -- Matches "ai" exactly or with leading/trailing spaces
      matches["ai"] = true
    elseif lowered:match("^%s*ai%?%s+") or lowered:match("%s+ai%?%s*$") then -- Starts or ends with "ai?"
      matches["ai?"] = true
    elseif lowered:match("^%s*ai!%s+") or lowered:match("%s+ai!%s*$") then   -- Starts or ends with "ai!"
      matches["ai!"] = true
    elseif lowered:match("^%s*ai%s+") or lowered:match("%s+ai%s*$") then     -- Starts or ends with "ai"
      matches["ai"] = true
    end
  end
  for _, v in pairs(matches) do
    if v then
      matches.any = true
    end
  end
  return matches
end

--- Get code comment text from a buffer
---@param bufnr
---@return nil|string[]
function M.get_comments(bufnr)
  local success, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not success or not parser then
    return nil
  end
  local tree = parser:parse()[1]
  if not tree then
    vim.notify("Aider.nvim failed to parse buffer " .. bufnr, vim.log.levels.DEBUG)
    return nil
  end
  local filetype = vim.bo[bufnr].filetype
  if not filetype then
    vim.notify("Aider.nvim failed to detect filetype for buffer " .. bufnr, vim.log.levels.DEBUG)
    return nil
  end
  local query_string = [[
(comment) @comment
]]
  local ok, query = pcall(vim.treesitter.query.parse, filetype, query_string)
  if not ok then
    vim.notify("Aider.nvim failed to parse query for filetype " .. filetype, vim.log.levels.DEBUG)
    return nil
  end
  local comments = {}
  for _, captures, _ in query:iter_matches(tree:root(), bufnr) do
    if captures[1] then -- captures[1] corresponds to @comment
      local node = captures[1]
      local start_row, start_col, end_row, end_col = node:range()

      -- Get all lines of the comment
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

      -- Process each line to remove delimiter and trim
      local comment_lines = {}
      for i, line in ipairs(lines) do
        if i == 1 then
          -- Find and remove the comment delimiter only on the first line
          line = M.remove_comment_chars(line)
        end
        -- Trim leading and trailing whitespace
        line = line:match("^%s*(.-)%s*$")
        table.insert(comment_lines, line)
      end

      -- Join the processed lines
      local text = table.concat(comment_lines, "\n")
      table.insert(comments, text)
    end
  end
  return comments
end

---@param bufnr
---@return table<string, boolean>
function M.buf_comment_matches(bufnr)
  local comments = M.get_comments(bufnr)
  return M.comment_matches(comments)
end

return M
