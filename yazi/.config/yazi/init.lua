require("full-border"):setup()
-- ~/.config/yazi/init.lua
--require("relative-motions"):setup({ show_numbers = "none", show_motion = true })
require("starship"):setup()

require("custom-shell"):setup({
	save_history = true,
	history_file = "default",
})
require("git"):setup()
require("copy-file-contents"):setup({
	clipboard_cmd = "default",
	append_char = "\n",
	notification = true,
})

require("mactag"):setup({
	-- Keys used to add or remove tags
	keys = {
		r = "Red",
		o = "Orange",
		y = "Yellow",
		g = "Green",
		b = "Blue",
		p = "Purple",
	},
	-- Colors used to display tags
	colors = {
		Red = "#ee7b70",
		Orange = "#f5bd5c",
		Yellow = "#fbe764",
		Green = "#91fc87",
		Blue = "#5fa3f8",
		Purple = "#cb88f8",
	},
})

local bookmarks = {}
-- require("whoosh"):setup({
-- 	-- Configuration bookmarks (cannot be deleted through plugin)
-- 	bookmarks = bookmarks,
--
-- 	-- Notification settings
-- 	jump_notify = false,
--
-- 	-- Key generation for auto-assigning bookmark keys
-- 	keys = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
--
-- 	-- File path for storing user bookmarks
-- 	path = os.getenv("HOME") .. "/dotfiles/yazi/.config/yazi/plugins/whoosh.yazi/bookmark",
--
-- 	-- Path truncation in navigation menu
-- 	path_truncate_enabled = false, -- Enable/disable path truncation
-- 	path_max_depth = 3, -- Maximum path depth before truncation
--
-- 	-- Path truncation in fuzzy search (fzf)
-- 	fzf_path_truncate_enabled = false, -- Enable/disable path truncation in fzf
-- 	fzf_path_max_depth = 5, -- Maximum path depth before truncation in fzf
--
-- 	-- Long folder name truncation
-- 	path_truncate_long_names_enabled = false, -- Enable in navigation menu
-- 	fzf_path_truncate_long_names_enabled = false, -- Enable in fzf
-- 	path_max_folder_name_length = 20, -- Max length in navigation menu
-- 	fzf_path_max_folder_name_length = 20, -- Max length in fzf
--
-- 	-- History directory settings
-- 	history_size = 10, -- Number of directories in history (default 10)
-- 	history_fzf_path_truncate_enabled = false, -- Enable/disable path truncation by depth for history
-- 	history_fzf_path_max_depth = 5, -- Maximum path depth before truncation for history (default 5)
-- 	history_fzf_path_truncate_long_names_enabled = false, -- Enable/disable long folder name truncation for history
-- 	history_fzf_path_max_folder_name_length = 30, -- Maximum length for folder names in history (default 30)
-- })

Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Span(ya.user_name() .. "@yazi" .. ":"):fg("blue")
end, 500, Header.LEFT)

Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	})
end, 500, Status.RIGHT)
