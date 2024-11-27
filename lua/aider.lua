local M = {}

local load_in_aider = function(selected, opts)
	local cleaned_paths = {}
	for _, entry in ipairs(selected) do
		local file_info = path.entry_to_file(entry, opts)
		table.insert(cleaned_paths, file_info.path)
	end
	local paths = table.concat(cleaned_paths, " ")

	if aider.buf and vim.api.nvim_buf_is_valid(aider.buf) then
		local paths_to_add = "/add " .. paths
		vim.fn.chansend(aider.job_id, paths_to_add .. "\n")
		vim.api.nvim_input("A")
		return
	end

	-- TODO close session if args don't match previous
	local aider_args = opts.aider_args or ""
	local command = "aider --cache-prompts " .. aider_args .. " " .. paths
	vim.api.nvim_command("vnew")
	aider.job_id = vim.fn.termopen(command, {
		on_exit = function()
			vim.cmd("bd!")
		end,
	})
	aider.buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_input("A")
end

local function toggle_aider()
	if aider.buf and vim.api.nvim_buf_is_valid(aider.buf) then
		-- Get list of windows containing the aider buffer
		local wins = vim.fn.win_findbuf(aider.buf)

		if #wins > 0 then
			-- Buffer is visible, close all windows containing it
			for _, win in ipairs(wins) do
				vim.api.nvim_win_close(win, false)
			end
		else
			-- Buffer isn't visible, show it in a vertical split
			vim.cmd("vnew")
			vim.api.nvim_win_set_buf(0, aider.buf)
			vim.api.nvim_input("A")
		end
	else
		load_in_aider({})
	end
end

local function get_visual_selection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
	else
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
	end
	return table.concat(lines, "\n")
end

local ask_with_selection = function()
	local selection = get_visual_selection()
	vim.notify("Selection: " .. selection)
	-- load_in_aider({}, { aider_args = "--chat-mode ask" })
	-- local command = "{\n" .. selection .. "\n}"
	-- vim.fn.chansend(aider.job_id, command .. "\n")
end
