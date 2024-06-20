require("anirudh.core.options")
require("anirudh.core.keymaps")
require("anirudh.lazy")

require("CopilotChat").setup({
	debug = true, -- Enable debugging
	-- See Configuration section for rest
})
vim.cmd([[ au BufRead,BufNewFile .tmux.conf set filetype=sh ]])
