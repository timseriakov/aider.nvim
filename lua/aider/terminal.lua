local config = require("aider").config

-- безопасная проверка use_tmux
if vim.env.TMUX and (config.use_tmux == true) then
	return require("aider.tmux")
end

---@class AiderTerminal: table
local term_mod = require("aider.toggleterm")

-- оборачиваем on_term_open
---@class AiderTerminal: table
local term_mod = require("aider.toggleterm")

vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "term://*toggleterm#*",
	callback = function(args)
		vim.schedule(function()
			vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
				buffer = args.buf,
				desc = "Exit terminal to Normal mode (double ESC)",
				noremap = true,
				silent = true,
			})
		end)
	end,
})

return term_mod
