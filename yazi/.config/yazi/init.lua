require("full-border"):setup()
-- ~/.config/yazi/init.lua
--require("relative-motions"):setup({ show_numbers = "relative", show_motion = true })
require("keyjump"):setup({
	icon_fg = "#fda1a1",
})

--require("archivemount"):setup()
-- Symlink
--require("git-status"):setup({
--	style = "linemode", -- beside or linemode
--})

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

local function status_owner()
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

Status:children_add(status_owner, 500, Status.RIGHT)

function Header_host()
	if ya.target_family() ~= "unix" then
		return ui.Line({})
	end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
end

Header:children_add(Header_host, 500, Header.LEFT)
