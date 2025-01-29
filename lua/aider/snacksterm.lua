local Terminal = require("snacks.terminal")
local config = require("aider").config
local utils = require("aider.utils")
local notify = require("aider.notify")
local aider = require("aider.aider")

---@class AiderTerminal
---@field __terms table<string, Terminal> Map of CWD to Terminal instances
local T = {
  __terms = {},
}

---@return boolean
function T.is_running()
  return T.__terms[utils.cwd()] ~= nil
end

function T.clear()
  local term = T.__terms[utils.cwd()]
  if term then
    term:close()
  end
  T.__terms[utils.cwd()] = nil
end

function T.clear_all()
  for _, term in ipairs(T.__terms) do
    if term then
      term:close()
    end
  end
  T.__terms = {}
end

function T.close_all()
  for _, term in ipairs(T.__terms) do
    term:close()
  end
end

--- Get or generate a terminal object for Aider
---@return snacks.win, boolean
function T.terminal()
  local cwd = Snacks.git.get_root()
  local term, created = Snacks.terminal.get(aider.command(), {
    cwd = cwd,
    env = aider.env(),
    interactive = true,
  })
  if not term then
    vim.notify("Failed to create terminal")
  end
  T.buf_id = term.buf
  if not T.buf_id then
    vim.notify("Failed to get terminal buf")
    return
  end
  T.job_id = vim.b[T.buf_id].terminal_job_id
  if not T.job_id then
    vim.notify("Failed to get terminal job id")
    return
  end
  T.__terms[cwd] = term

  return term, created
end

---Load files into aider session
---@param files table|nil Files or path
function T.add(files)
  files = files or {}
  if #files > 0 then
    -- Convert relative paths to absolute paths
    local abs_files = {}
    for _, file in ipairs(files) do
      table.insert(abs_files, vim.fn.fnamemodify(file, ":p"))
    end
    local cmd = "/add " .. table.concat(abs_files, " ")
    T.send_command(cmd)
  end
end

---Load files into aider session
---@param files table|nil Files or path
function T.read_only(files)
  files = files or {}
  if #files > 0 then
    local cmd = "/read-only " .. table.concat(files, " ")
    T.send_command(cmd)
  end
end

function T.drop(files)
  files = files or {}
  if #files > 0 then
    local cmd = "/drop " .. table.concat(files, " ")
    T.send_command(cmd)
  end
end

function T.open()
  local term = T.terminal()
  term:show()
end

---@param size? number|nil
---@param direction? string|nil
function T.toggle_window(size, direction)
  local bufnr = vim.fn.bufnr("%")
  if T.buf_id == bufnr then
    vim.api.nvim_win_close(0, false)
    return
  else
    local term, created = T.terminal()
    if not created then
      term:show()
    end
  end
end

--- Send a command to the active Aider terminal session
--- If no terminal is currently open, it will first create a new terminal
--- @param command string The command to send to the Aider session
function T.send_command(command)
  if string.find(command, "\n") then
    local cmd_start = "{EOL\n"
    local cmd_end = "\nEOL}"
    command = cmd_start .. command .. cmd_end
  end
  command = command .. "\n"

  T.terminal()
  vim.fn.chansend(T.job_id, command)
end

--- Send an AI query to the Aider session
--- @param prompt string The query or instruction to send
--- @param selection string? Optional selected text to include with the prompt
function T.ask(prompt, selection)
  if not prompt or #vim.trim(prompt) == 0 then
    vim.notify("No input provided", vim.log.levels.WARN)
    return
  end

  local command
  if selection then
    prompt = string.format("%s\n%s", prompt, selection)
  end

  command = "/ask " .. prompt
  T.send_command(command)
end

return T
