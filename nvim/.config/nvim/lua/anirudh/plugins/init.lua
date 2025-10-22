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
	-- {
	-- 	"nvim-java/nvim-java",
	-- 	require("java").setup(),
	-- 	require("lspconfig").jdtls.setup({}),
	-- },
}
