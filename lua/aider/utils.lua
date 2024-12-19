local M = {}
--- Clean line outputs for aider
---@param line string
---@return string
function M.clean_output(line)
	-- Remove EOF delimiters
	line = line:gsub(".*{EOF.*", "")
	line = line:gsub(".*EOF}.*", "")
	-- Remove cursor style codes
	line = line:gsub("%[%d+ q", "")
	-- Handle RGB color codes and extended ANSI sequences
	line = line:gsub("\27%[38;2;%d+;%d+;%d+m", "") -- RGB foreground
	line = line:gsub("\27%[48;2;%d+;%d+;%d+m", "") -- RGB background
	line = line:gsub("\27%[%d+;%d+;%d+;%d+;%d+m", "") -- Multiple color parameters
	-- Enhanced RGB and extended color handling
	line = line:gsub("\27%[%d+;%d+;%d+;%d+;%d+;%d+;%d+;%d+m", "") -- Extended color with multiple parameters
	line = line:gsub("\27%[38;2;%d+;%d+;%d+;48;2;%d+;%d+;%d+m", "") -- RGB fore/background combined
	line = line:gsub("\27%[48;2;%d+;%d+;%d+;38;2;%d+;%d+;%d+m", "") -- RGB back/foreground combined
	-- New patterns to catch RGB codes without escape character
	line = line:gsub("38;2;%d+;%d+;%d+;48;2;%d+;%d+;%d+m", "") -- RGB fore/background without escape
	line = line:gsub("48;2;%d+;%d+;%d+;38;2;%d+;%d+;%d+m", "") -- RGB back/foreground without escape
	line = line:gsub("38;2;%d+;%d+;%d+m", "") -- Single RGB foreground without escape
	line = line:gsub("48;2;%d+;%d+;%d+m", "") -- Single RGB background without escape
	-- Catch any remaining color codes with semicolons
	line = line:gsub("%[([%d;]+)m", "")
	line = line:gsub("([%d;]+)m", "") -- New pattern to catch remaining codes without brackets
	-- Remove standard ANSI escape sequences
	line = line:gsub("\27%[%?%d+[hl]", "")
	line = line:gsub("\27%[[%d;]*[A-Za-z]", "")
	line = line:gsub("\27%[%d*[A-Za-z]", "")
	line = line:gsub("\27%(%[%d*;%d*[A-Za-z]", "")
	-- Remove line numbers and decorators that appear in your output
	line = line:gsub("^%s*%d+%s*│%s*", "") -- Remove line numbers and vertical bars
	line = line:gsub("^%s*▎?│%s*", "") -- Remove just vertical bars with optional decorators
	-- Remove control characters
	line = line:gsub("[\r\n]", "")
	line = line:gsub("[\b]", "")
	line = line:gsub("[\a]", "")
	line = line:gsub("[\t]", "    ")
	line = line:gsub("[%c]", "")
	-- Remove leading '>' character if it's alone on a line
	line = line:gsub("^%s*>%s*$", "")
	-- Remove or clean up file headers
	line = line:gsub("^%s*lua/[%w/_]+%.lua%s*$", "")
	-- Remove the (Nx) count indicators
	line = line:gsub("%(%d+x%)", "")
	-- Remove trailing "INFO" markers
	line = line:gsub("%s*INFO%s*$", "")
	-- Remove empty lines after cleaning
	if line:match("^%s*$") then
		return ""
	end
	return line
end

---@return string
function M.cwd()
	return vim.fn.getcwd(-1, -1)
end

function M.truncate_message(msg, max_length)
	if #msg > max_length then
		return msg:sub(1, max_length - 3) .. "..."
	end
	return msg
end
return M
