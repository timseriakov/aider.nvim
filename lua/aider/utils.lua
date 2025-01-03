local M = {}

--- Clean line outputs for aider
---@param line string
---@return string
function M.clean_output(line)
  local gsub_patterns = {
    { ".*{EOF.*" },
    { ".*EOF}.*" },
    { "%[%d+ q" },
    { "\27%[38;2;%d+;%d+;%d+m" },
    { "\27%[48;2;%d+;%d+;%d+m" },
    { "\27%[%d+;%d+;%d+;%d+;%d+m" },
    { "\27%[%d+;%d+;%d+;%d+;%d+;%d+;%d+;%d+m" },
    { "\27%[38;2;%d+;%d+;%d+;48;2;%d+;%d+;%d+m" },
    { "\27%[48;2;%d+;%d+;%d+;38;2;%d+;%d+;%d+m" },
    { "38;2;%d+;%d+;%d+;48;2;%d+;%d+;%d+m" },
    { "48;2;%d+;%d+;%d+;38;2;%d+;%d+;%d+m" },
    { "38;2;%d+;%d+;%d+m" },
    { "48;2;%d+;%d+;%d+m" },
    { "%[([%d;]+)m" },
    { "([%d;]+)m" },
    { "\27%[%?%d+[hl]" },
    { "\27%[[%d;]*[A-Za-z]" },
    { "\27%[%d*[A-Za-z]" },
    { "\27%(%[%d*;%d*[A-Za-z]" },
    { "^%s*%d+%s*│%s*" },
    { "^%s*▎?│%s*" },
    { "[\r\n]" },
    { "[\b]" },
    { "[\a]" },
    { "[\t]", "  " },
    { "[%c]" },
    { "^%s*>%s*$" },
    { "^%s*lua/[%w/_]+%.lua%s*$" },
    { "%(%d+x%)" },
    { "%s*INFO%s*$" },
  }

  for _, pattern in ipairs(gsub_patterns) do
    line = line:gsub(pattern[1], pattern[2] or "")
  end

  if line:match("^%s*$") then
    return ""
  end
  return line
end

---@return string
function M.cwd()
  return vim.fn.getcwd(-1, -1)
end

---@return string
function M.truncate_message(msg, max_length)
  if #msg > max_length then
    return msg:sub(1, max_length - 3) .. ".."
  end
  return msg
end

local function remove_comment_chars(comment)
  return comment:gsub("^%s*([%-%-/%#]+%s*)", "")
end

---@param comments table|nil
---@return table<string, boolean>
local function comment_matches(comments)
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
          line = remove_comment_chars(line)
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
  return comment_matches(comments)
end

return M
