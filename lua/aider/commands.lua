local terminal = require("aider.terminal")
local selection = require("aider.selection")

local M = {}

---Create user commands for aider functionality
function M.setup()
	vim.api.nvim_create_user_command("AiderToggle", function()
		terminal.toggle()
	end, {
		desc = "Toggle Aider window",
	})

	vim.api.nvim_create_user_command("AiderLoad", function(opts)
		local files = opts.fargs
		if #files == 0 then
			files = { vim.api.nvim_buf_get_name(0) }
		end
		terminal.load_in_aider(files)
	end, {
		nargs = "*",
		desc = "Load files into Aider",
		complete = "file",
	})

	local function handle_aider_send(opts)
		if opts.range == 0 then
			-- No selection, just use the arguments
			if not opts.args or opts.args:trim() == "" then
				vim.notify("Empty input provided", vim.log.levels.WARN)
				return
			end
			terminal.aider_send(opts.args)
			return
		end

		-- Get the selected text
		local selected = selection.get_visual_selection()
		if not selected then
			vim.notify("Failed to get visual selection", vim.log.levels.ERROR)
			return
		end

		local selected_text = table.concat(selected, "\n")
		-- Combine selection with any additional arguments
		local input = opts.args and opts.args ~= "" and string.format("%s\n%s", opts.args, selected_text)
			or selected_text

		terminal.aider_send(input)
	end

	vim.api.nvim_create_user_command("AiderSend", handle_aider_send, {
		nargs = "*",
		range = true, -- This enables the command to work with selections
		desc = "Send command to Aider",
		bang = true,
	})

	local function process_prompt(input, opts)
		if not input or input:trim() == "" then
			vim.notify("Empty input provided", vim.log.levels.WARN)
			return
		end

		local selected_text = ""
		if opts.range ~= 0 then
			local selected = selection.get_visual_selection()
			if not selected then
				vim.notify("Failed to get visual selection", vim.log.levels.ERROR)
				return
			end
			selected_text = table.concat(selected, "\n")
		end

		terminal.ask(input, selected_text)
		vim.notify("Question sent to Aider", vim.log.levels.INFO)
	end

	local function handle_aider_ask(opts)
		if #opts.args > 0 then
			process_prompt(opts.args, opts)
		else
			vim.schedule(function()
				vim.ui.input({ prompt = "Prompt: " }, function(input)
					process_prompt(input, opts)
				end)
			end)
		end
	end

	vim.api.nvim_create_user_command("AiderAsk", handle_aider_ask, {
		range = true,
		nargs = "*",
		desc = "Ask with visual selection",
		bang = true,
	})
end

return M
