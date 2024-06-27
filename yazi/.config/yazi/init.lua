require("full-border"):setup()
-- ~/.config/yazi/init.lua
require("relative-motions"):setup({ show_numbers = "relative", show_motion = true })
-- ~/.config/yazi/init.lua
require("bookmarks"):setup({
	save_last_directory = false,
	persist = "vim",
	desc_format = "full",
	notify = {
		enable = true,
		timeout = 5,
		message = {
			new = "New bookmark '<key>' -> '<folder>'",
			delete = "Deleted bookmark in '<key>'",
			delete_all = "Deleted all bookmarks",
		},
	},
})
