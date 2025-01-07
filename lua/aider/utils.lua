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

-- what does this return ai?
---@return string|nil
function M.get_git_root()
  local dot_git = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
  return dot_git ~= "" and vim.fn.fnamemodify(dot_git, ":h") or nil
end

---@return string
function M.cwd()
  return M.get_git_root() or vim.fn.getcwd()
end

---@return string
function M.truncate_message(msg, max_length)
  if #msg > max_length then
    return msg:sub(1, max_length - 3) .. ".."
  end
  return msg
end

return M
