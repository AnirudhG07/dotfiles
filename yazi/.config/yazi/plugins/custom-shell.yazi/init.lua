local selected_or_hovered = ya.sync(function()
	local tab, paths = cx.active, {}
	for _, u in pairs(tab.selected) do
		paths[#paths + 1] = tostring(u)
	end
	if #paths == 0 and tab.current.hovered then
		paths[1] = tostring(tab.current.hovered.url)
	end
	return paths
end)

local function shell_choice(shell_val)
	-- input is in lowercase always
	local alt_name_map = {
		kornshell = "ksh",
		powershell = "pwsh",
		nushell = "nu",
	}

	local shell_map = {
		bash = { shell_val = "bash", supporter = "-ic" },
		zsh = { shell_val = "zsh", supporter = "-ic" },
		fish = { shell_val = "fish", supporter = "-c" },
		pwsh = { shell_val = "pwsh", supporter = "-Command" },
		sh = { shell_val = "sh", supporter = "-c" },
		ksh = { shell_val = "ksh", supporter = "-c" },
		csh = { shell_val = "csh", supporter = "-c" },
		tcsh = { shell_val = "tcsh", supporter = "-c" },
		dash = { shell_val = "dash", supporter = "-c" },
		nu = { shell_val = "nu", supporter = "-ic" },
	}

	shell_val = alt_name_map[shell_val] or shell_val
	local shell_info = shell_map[shell_val]

	if shell_info then
		return shell_info.shell_val, shell_info.supporter
	else
		return nil, "-c"
	end
end

local function manage_extra_args(args)
	-- set default values, --custom-shell.yazi does not use --interactive but --confirm.
	local block, confirm, orphan = true, true, false
	for _, arg in ipairs(args) do
		if arg == "-nb" or arg == "--no-block" then
			block = false
		elseif arg == "-nc" or arg == "--no-confirm" then
			confirm = false
		elseif arg == "-o" or arg == "--orphan" then
			orphan = true
		end
	end

	return block, confirm, orphan
end

local function entry(_, args)
	local shell_env = os.getenv("SHELL"):match(".*/(.*)")
	local shell_value = ""

	if args[1] == "auto" then
		shell_value = shell_env:lower()
	elseif args[1] == "custom" then
		shell_value = args[2]
	else
		shell_value = args[1]:lower()
	end

	local shell_val, supp = shell_choice(shell_value:lower())
	if shell_val == nil then
		ya.notify("Unsupported shell: " .. shell_value .. "Choosing Default Shell: " .. shell_env)
		shell_val, supp = shell_choice(shell_env)
	end

	local block, confirm, orphan = manage_extra_args(args)
	local input_title = shell_value .. " Shell " .. (block and "(block)" or "") .. ": "
	local paths = selected_or_hovered()

	local exec_cmd, cmd, event = shell_val .. " " .. supp .. " ", "", 1
	if args[1] ~= "custom" then
		cmd, event = ya.input({
			title = input_title,
			position = { "top-center", y = 3, w = 40 },
		})
	else
		cmd = args[3]
	end

	if args[1] == "custom" then
		exec_cmd = exec_cmd .. ya.quote(cmd .. "; exit", true)
	elseif shell_val == "fish" then
		exec_cmd = exec_cmd
			.. string.format('"set -g 0 %s;set -g argv %s; %s"', paths, cmd:gsub("%$", "\\$"):gsub('"', '\\"'))
	else -- for other shells
		exec_cmd = exec_cmd .. string.format('"%s; exit" %s %s', cmd:gsub("%$", "\\$"):gsub('"', '\\"'), paths)
	end

	if event == 1 then
		ya.manager_emit("shell", {
			exec_cmd,
			block = block,
			confirm = confirm,
			orphan = orphan,
		})
	end
end

return {
	entry = entry,
}
