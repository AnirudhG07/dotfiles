-- This machine's Neovim extras, on top of the core in lua/anirudh/core/tools.lua
-- (core = pyright + ruff + clangd via mason, and the treesitter parsers listed there).
--
-- setup.sh copies this file to lua/anirudh/machine.lua on a machine that has none.
-- machine.lua is gitignored: each machine keeps its own, and edits there never reach git.
-- After editing: restart nvim (mason and treesitter install what's new in the background),
-- or run :MasonToolsInstall.
return {
	-- mason package names, or lspconfig server names. Examples:
	--   "lua_ls", "html", "ty", "marksman", "tinymist",      -- language servers
	--   "prettier", "stylua", "isort",                       -- formatters (conform.nvim)
	mason = {},

	-- extra treesitter parsers. latex needs the real tree-sitter CLI (not tree-sitter-cc).
	treesitter = {},
}
