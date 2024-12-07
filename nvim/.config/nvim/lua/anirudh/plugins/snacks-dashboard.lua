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
					cmd = "pokemon-colorscripts -r",
					random = 10,
					pane = 2,
					indent = 4,
					height = 30,
				},
			},
		},
	},
}
