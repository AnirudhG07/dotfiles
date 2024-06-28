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
require("keyjump"):setup({
	icon_fg = "#fda1a1",
})
-- Symlink
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
function Header:host()
	if ya.target_family() ~= "unix" then
		return ui.Line({})
	end
	return ui.Span(ya.user_name() .. "@yazi" .. ": "):fg("blue")
end
function Header:render(area)
	self.area = area

	local right = ui.Line({ self:count(), self:tabs() })
	local left = ui.Line({ self:host(), self:cwd(math.max(0, area.w - right:width())) })
	return {
		ui.Paragraph(area, { left }),
		ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
	}
end

-- group of files and username at the bottom
function Status:owner()
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
function Status:render(area)
	self.area = area

	local left = ui.Line({ self:mode(), self:size(), self:name() })
	local right = ui.Line({ self:owner(), self:permissions(), self:percentage(), self:position() })
	return {
		ui.Paragraph(area, { left }),
		ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
		table.unpack(Progress:render(area, right:width())),
	}
end
