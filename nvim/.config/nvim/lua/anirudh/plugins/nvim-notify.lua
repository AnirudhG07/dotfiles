return {
	"rcarriga/nvim-notify",
	config = function()
		require("notify").setup({
			stages = "fade",
			timeout = 5000,
			background_colour = "blue", -- blue color
			text_colour = "black",
			icons = {
				ERROR = "",
				WARN = "",
				INFO = "",
				DEBUG = "",
				TRACE = "✎",
			},
		})
	end,
}
