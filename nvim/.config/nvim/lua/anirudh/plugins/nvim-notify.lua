return {
	"rcarriga/nvim-notify",
	config = function()
		require("notify").setup({
			stages = "fade_in_slide_out",
			timeout = 500,
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
