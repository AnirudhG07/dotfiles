-- What Neovim installs: a small core every machine gets, plus this machine's extras.
--
--   core (here, tracked):          mason -> Python + C/C++ language servers only
--                                  treesitter -> parsers that build with just a C compiler
--   extras (lua/anirudh/machine.lua, gitignored; start from machine.example.lua):
--                                  whatever this machine also wants (lua_ls, prettier, latex, ...)
--
-- setup.sh's headless bootstrap reads these lists too, so the two never drift.
local M = {}

-- Mason package names (lspconfig names work too, e.g. "lua_ls").
-- `exe` = the binary; when the system already has it (apt clangd, `uv tool install ruff`),
-- mason doesn't install a second copy and the system one is used.
M.core_mason = {
	{ name = "pyright", exe = "pyright-langserver" }, -- python: types, hover, go-to
	{ name = "ruff", exe = "ruff" }, -- python: lint + format
	{ name = "clangd", exe = "clangd" }, -- C / C++
}

-- latex is not here: it is one of the few parsers that must be *generated*, which needs the
-- real tree-sitter CLI (tree-sitter-cc only builds). Add it per machine where that CLI runs.
M.core_treesitter = {
	"bash",
	"c",
	"css",
	"csv",
	"dockerfile",
	"gitignore",
	"go",
	"gomod",
	"gosum",
	"graphql",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"php",
	"prisma",
	"python",
	"query",
	"rust",
	"svelte",
	"tsx",
	"typescript",
	"typst",
	"vim",
	"vimdoc",
	"yaml",
}

local function load_machine()
	local ok, m = pcall(require, "anirudh.machine")
	if ok then
		return type(m) == "table" and m or {}
	end
	if not tostring(m):find("module 'anirudh.machine' not found", 1, true) then
		vim.schedule(function()
			vim.notify("lua/anirudh/machine.lua has an error:\n" .. tostring(m), vim.log.levels.WARN)
		end)
	end
	return {}
end

M.machine = load_machine()

local function on_system(exe)
	local path = vim.fn.exepath(exe)
	return path ~= "" and not path:find("/mason/bin/", 1, true)
end

local function uniq(list)
	local seen, out = {}, {}
	for _, v in ipairs(list) do
		if not seen[v] then
			seen[v], out[#out + 1] = true, v
		end
	end
	return out
end

-- what mason-tool-installer should ensure: core servers the system lacks + this machine's extras
function M.mason()
	local list = {}
	for _, s in ipairs(M.core_mason) do
		if not on_system(s.exe) then
			list[#list + 1] = s.name
		end
	end
	return uniq(vim.list_extend(list, M.machine.mason or {}))
end

-- core servers the system provides: mason-lspconfig only auto-enables what mason installed,
-- so these are enabled by name (see lsp/mason.lua)
function M.system_servers()
	local names = {}
	for _, s in ipairs(M.core_mason) do
		if on_system(s.exe) then
			names[#names + 1] = s.name
		end
	end
	return names
end

function M.treesitter()
	return uniq(vim.list_extend(vim.deepcopy(M.core_treesitter), M.machine.treesitter or {}))
end

return M
