return {
	{
		"mrcjkb/rustaceanvim",
		version = "^6", -- Recommended
		ft = { "rust" },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			setup = {
				rust_analyzer = function()
					return true
				end,
			},
		},
	},
}
