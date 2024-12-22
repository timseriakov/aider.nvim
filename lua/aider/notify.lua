local config = require("aider").config
local utils = require("aider.utils")

local M = {}

local CONSTANTS = {
	DEFAULT_TITLE = "Aider.nvim",
	NOTIFICATION_ID = "aider",
	YES_NO_PATTERN = "%(Y%)es/%(N%)o",
}

local MessageBuffer = {
	messages = {},
	capacity = 50,
	current = 0,
}

function MessageBuffer:add(msg)
	self.current = (self.current % self.capacity) + 1
	self.messages[self.current] = msg
end

function MessageBuffer:contains(msg)
	for _, stored_msg in pairs(self.messages) do
		if stored_msg == msg then
			return true
		end
	end
	return false
end

local function progress_notifier()
	local snacks, snotifier = pcall(require, "snacks.notifier")
	if not snacks then
		vim.notify("snacks.nvim is required for progress notifications", vim.log.levels.WARN)
	end
	local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
	local msg = "Aider Working ..."
	snotifier.notify(msg, "info", {
		id = "aider_progress",
		title = "Aider",
		style = config.progress_notifier.style,
		opts = function(notif)
			notif.icon = spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
		end,
	})
end

local function log_notifier(line)
	local message_buffer = MessageBuffer
	local fidget, fnotifier = pcall(require, "fidget")
	if not fidget then
		return
	end
	local msg = utils.clean_output(line)
	if #msg > 20 and msg:match("[a-z]") then
		-- Check if message is duplicate before processing
		msg = utils.truncate_message(msg, 60)
		if not message_buffer:contains(msg) then
			message_buffer:add(msg)
			fnotifier.notify(msg, vim.log.levels.INFO, {
				title = CONSTANTS.DEFAULT_TITLE,
				id = CONSTANTS.NOTIFICATION_ID,
				replace = CONSTANTS.NOTIFICATION_ID,
			})
		end
	end
end

local Terminal = require("toggleterm.terminal").Terminal

---@param term Terminal
---@param data table
function M.on_stdout(term, data)
	for _, line in ipairs(data) do
		if term:is_open() then
			return
		end

		if line:match(CONSTANTS.YES_NO_PATTERN) then
			term:open()
			return
		end

		if config.progress_notifier then
			progress_notifier()
		end

		if config.log_notifier then
			log_notifier(line)
		end
	end
end

return M
