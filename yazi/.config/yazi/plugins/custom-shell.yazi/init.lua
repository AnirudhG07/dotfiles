local Shell_value = os.getenv("SHELL"):match(".*/(.*)")

local function emit(cmd, args, shell_value)
	ya.notify({ title = "nothing", content = cmd, timeout = 2 })
	if args ~= "manager" then
		ya.manager_emit("shell", {
			shell_value .. " -ic " .. ya.quote(cmd .. "; exit", true),
			block = true,
			confirm = true,
		})
	else
		-- args=manager
		--
		ya.notify({ title = "nothing", content = "manager " .. ya.quote(cmd), timeout = 2 })
		ya.manager_emit(ya.quote(cmd))
	end
end

local function entry(_, args)
	local prompt
	local shell_value = Shell_value

	if args[1] == "manager" then
		prompt = "Manager:"
	elseif args[1] ~= "auto" then
		shell_value = args[1]
		prompt = shell_value .. " Shell:"
	end

	local value, event = ya.input({
		title = prompt,
		position = { "top-center", y = 3, w = 40 },
	})
	ya.notify({ title = "nothing", content = value, timeout = 2 })
	if event == 1 then
		emit(value, args[1], shell_value)
	end
end

return {
	entry = entry,
}
