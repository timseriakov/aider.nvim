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

	vim.api.nvim_create_user_command("AiderAsk", function()
		local mode = vim.fn.mode()
		local is_visual = mode == "v" or mode == "V"

		vim.schedule(function()
			vim.ui.input({ prompt = "Prompt: " }, function(input)
				if not input then
					return
				end

				local selected_text = ""
				if is_visual then
					local selected = selection.get_visual_selection()
					selected_text = table.concat(selected, "\n")
				end

				terminal.ask(input, selected_text)
			end)
		end)
	end, {
		range = true,
		desc = "Ask with visual selection",
	})
end

return M
