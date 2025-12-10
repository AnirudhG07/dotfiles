-- These are plugins that are just good with defaults.
return {
	"nvim-lua/plenary.nvim", -- lua functions that many plugins use
	"christoomey/vim-tmux-navigator", -- tmux & split window navigation
	"folke/tokyonight.nvim",
	"nvim-telescope/telescope.nvim", -- telescope
	{
		"MeanderingProgrammer/render-markdown.nvim", -- Markdown rendering
		event = "VeryLazy",
	},
	{
		"kevinhwang91/nvim-bqf",
		event = "VeryLazy",
	},
	"lewis6991/satellite.nvim",
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
