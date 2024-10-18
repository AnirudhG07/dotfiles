return {
	"Julian/lean.nvim",
	event = { "BufReadPre *.lean", "BufNewFile *.lean" },

	dependencies = {
		"neovim/nvim-lspconfig",
		"nvim-lua/plenary.nvim",
		"lewis6991/satellite.nvim",
		-- you also will likely want nvim-cmp or some completion engine
	},

	-- see details below for full configuration options
	opts = {
		lsp = {},
		mappings = true,
		infoview = {
			width = 60,
		},
	},
}
