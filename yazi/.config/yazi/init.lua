require("full-border"):setup()
-- ~/.config/yazi/init.lua
--require("relative-motions"):setup({ show_numbers = "none", show_motion = true })
require("starship"):setup()
require("git"):setup({})

require("mactag"):setup({
	-- You can change the colors of the tags here
	colors = {
		Red = "ee7b70",
		Orange = "f5bd5c",
		Yellow = "fbe764",
		Green = "91fc87",
		Blue = "5fa3f8",
		Purple = "cb88f8",
		Gray = "b5b5b9",
	},
})

function Status:name()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end
	local linked = ""
	if h.link_to ~= nil then
		linked = " -> " .. tostring(h.link_to)
	end
	return ui.Span(" " .. h.name .. linked)
end

-- Header name
function header_host()
	if ya.target_family() ~= "unix" then
		return ui.Line({})
	end
	return ui.Span(ya.user_name() .. "@yazi" .. ": "):fg("blue")
end

Header:children_add(header_host, 500, Header.LEFT)
-- group of files and username at the bottom
function Status_owner()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ui.Line({})
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		ui.Span(":"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		ui.Span(" "),
	})
end

Status:children_add(Status_owner, 500, Status.RIGHT)
