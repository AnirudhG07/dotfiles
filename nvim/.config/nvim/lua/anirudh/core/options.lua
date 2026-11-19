vim.cmd("let g:netrw_liststyle =3")

local opt = vim.opt -- for conciseness

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 4 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = true -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- Over SSH (or in a herdr terminal on a remote / headless Linux box) the "system clipboard"
-- would be the remote's own, or none. Use OSC 52 instead: yanks travel as an escape sequence
-- to the terminal you're sitting at (ghostty, herdr-app, iTerm, kitty, WezTerm, tmux with
-- set-clipboard on) and land in *your* clipboard. Built into Neovim >= 0.10, no plugin.
-- Paste reads nvim's own last yank: terminals block or prompt on OSC 52 *reads*, which would
-- stall every `p`. To paste something copied on your machine, use the terminal's paste (⌘V).
local remote = vim.env.SSH_TTY or vim.env.SSH_CONNECTION
local headless_linux = vim.fn.has("linux") == 1 and not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY
if remote or headless_linux then
	local osc52 = require("vim.ui.clipboard.osc52")
	local function paste()
		return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
	end
	vim.g.clipboard = {
		name = "OSC 52",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = paste, ["*"] = paste },
	}
end

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.swapfile = false

-- folding (previously configured by nvim-ufo; Neovim 0.12 does this natively).
-- The actual foldexpr is set per-buffer in plugins/treesitter.lua, so that only
-- buffers treesitter can parse get treesitter folds.
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldcolumn = "1"
-- table form: the string form is easy to corrupt if a glyph is lost
opt.fillchars = {
	eob = " ",
	fold = " ",
	foldopen = "\u{25BE}", -- black down-pointing small triangle
	foldsep = " ",
	foldclose = "\u{25B8}", -- black right-pointing small triangle
}

-- LSP logging: lsp.log had grown to 143 MB (html-lsp was spamming validation
-- errors on every keystroke). Every write also costs I/O on the main loop.
-- Set to "warn" or "debug" temporarily when actually debugging a server.
if vim.lsp.log and vim.lsp.log.set_level then
	vim.lsp.log.set_level(vim.lsp.log.levels.OFF) -- nvim 0.12+
else
	vim.lsp.set_log_level("off")
end
