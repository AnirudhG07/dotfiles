local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(
	{ { import = "anirudh.plugins" }, { import = "anirudh.plugins.lsp" }, { import = "anirudh.plugins.snacks" } },
	{
		colorscheme = {
			scheme = "tokyonight",
			config = {
				darkSidebar = true,
				darkFloat = true,
			},
		},
		checker = {
			enabled = false, -- was git-fetching all ~70 plugins on startup; use :Lazy check
			notify = false,
		},
		change_detection = {
			notify = false,
		},
		performance = {
			rtp = {
				disabled_plugins = {
					"gzip",
					"tarPlugin",
					"tohtml",
					"tutor",
					"zipPlugin",
				},
			},
		},
	}
)
