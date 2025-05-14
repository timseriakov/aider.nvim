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
			-- Double ESC → выйти из терминала
			vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
				buffer = args.buf,
				desc = "Exit terminal to Normal mode (double ESC)",
				noremap = true,
				silent = true,
			})

			-- q → скрыть терминал (в Normal mode)
			vim.keymap.set("n", "q", function()
				vim.cmd("AiderToggle")
			end, {
				buffer = args.buf,
				desc = "Close Aider terminal with q",
				noremap = true,
				silent = true,
			})
		end)
	end,
})

return term_mod
