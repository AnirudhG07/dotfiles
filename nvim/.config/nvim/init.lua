require("anirudh.core.options")
require("anirudh.core.keymaps")
require("anirudh.lazy")

vim.cmd([[ au BufRead,BufNewFile .tmux.conf set filetype=sh ]])
