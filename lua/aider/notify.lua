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

--- Write data to a temporary markdown file
---@param data string[]
local function write_to_file(data)
	local chat_file = "/tmp/aider.md"

	vim.fn.writefile(data, chat_file, "a")
end

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

function M.on_stdout(term, data)
	local message_buffer = MessageBuffer

	for _, line in ipairs(data) do
		write_to_file(line)
		if term:is_open() then
			return
		end

		if line:match(CONSTANTS.YES_NO_PATTERN) then
			term:open()
			return
		end

		local msg = utils.clean_output(line)
		if #msg > 0 then
			-- Check if message is duplicate before processing
			msg = utils.truncate_message(msg, 60)
			if not message_buffer:contains(msg) then
				message_buffer:add(msg)
				config.notify(msg, vim.log.levels.INFO, {
					title = CONSTANTS.DEFAULT_TITLE,
					id = CONSTANTS.NOTIFICATION_ID,
					replace = CONSTANTS.NOTIFICATION_ID,
				})
			end
		end
	end
end

return M
