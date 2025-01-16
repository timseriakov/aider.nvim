local M = {}

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

local pattern_first = "^%s*([#/%-][-/]?)%s+ai[!?]?%s*(.*)$" -- Matches 'ai' as first word after comment
local pattern_last = "^%s*([#/%-][-/]?)%s+.*%sai[!?]?%s*$"  -- Matches 'ai' as last word
local remove_whitespace = "^%s*(.-)%s*$"

function M.get_comments_regex(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local comments = {}
  for _, line in ipairs(lines) do
    line = line:lower()
    if line:match(pattern_first) or line:match(pattern_last) then
      line = M.remove_comment_chars(line)
      line = line:match(remove_whitespace)
      table.insert(comments, line)
    end
  end
  return comments
end

--- Get code comment text from a buffer
---@param bufnr integer
---@return nil|string[]
function M.get_comments(bufnr)
  local success, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not success or not parser then
    return nil
  end
  local tree = parser:parse()[1]
  local filetype = vim.bo[bufnr].filetype
  if not tree or not filetype then
    return M.get_comments_regex(bufnr)
  end
  local query_string = [[
(comment) @comment
]]
  local ok, query = pcall(vim.treesitter.query.parse, filetype, query_string)
  if not ok then
    return M.get_comments_regex(bufnr)
  end
  local comments = {}
  for _, captures, _ in query:iter_matches(tree:root(), bufnr, nil, nil, { all = false }) do
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
        line = line:match(remove_whitespace)
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
  local comments = M.get_comments(bufnr) or {}
  return M.comment_matches(comments)
end

return M
