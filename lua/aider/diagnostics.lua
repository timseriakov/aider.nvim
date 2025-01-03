local M = {}

function M.format(diagnostics)
  local output = {}
  local severity_map = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }
  for _, diag in ipairs(diagnostics) do
    local line = string.format(
      "Line %d, Col %d: [%s] %s (%s)",
      diag.lnum + 1, -- Convert from 0-based to 1-based line numbers
      diag.col + 1,  -- Convert from 0-based to 1-based column numbers
      severity_map[diag.severity] or "UNKNOWN",
      diag.message,
      diag.source or "unknown"
    )
    table.insert(output, line)
  end
  return output
end

return M
