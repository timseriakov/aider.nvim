local config = require("aider").config
if vim.env.TMUX and config.use_tmux then
	return require("aider.tmux")
end
return require("aider.toggleterm")
