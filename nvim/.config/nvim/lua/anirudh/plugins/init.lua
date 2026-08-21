-- These are plugins that are just good with defaults.
return {
	{ "nvim-lua/plenary.nvim", lazy = true }, -- lua functions that many plugins use
	{ "christoomey/vim-tmux-navigator", event = "VeryLazy" }, -- tmux & split window navigation
	-- tokyonight is specced in colorscheme.lua (priority 1000)
	{
		"MeanderingProgrammer/render-markdown.nvim", -- Markdown rendering
		ft = { "markdown", "codecompanion", "Avante" },
	},
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
	},
	{ "lewis6991/satellite.nvim", event = "VeryLazy" },
	{
		"szw/vim-maximizer",
		keys = {
			{ "<leader>sm", "<cmd>MaximizerToggle<CR>", desc = "Maximize/minimize a split" },
		},
	},

	-- surround
	{
		"kylechui/nvim-surround",
		event = { "BufReadPre", "BufNewFile" },
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		config = true,
	},
}
