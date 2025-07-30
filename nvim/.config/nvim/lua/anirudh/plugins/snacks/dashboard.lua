return {
	"folke/snacks.nvim",
	opts = {
		dashboard = {
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ section = "startup" },
				{
					section = "terminal",
					cmd = "krabby random --no-mega --no-gmax",
					random = 1000,
					pane = 2,
					indent = 4,
					height = 30,
				},
			},
		},
	},
}
