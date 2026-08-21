-- nvim-treesitter `main` branch.
--
-- The `master` branch is frozen and explicitly does NOT support Neovim 0.12
-- (see its README). On 0.12 its custom query directives break: the markdown
-- injections query used `(#set-lang-from-info-string! @_lang)`, whose handler
-- assumed `match[id]` was a single TSNode rather than a list, so every markdown
-- redraw threw "attempt to call method 'range' (a nil value)" out of the
-- treesitter decoration provider.
--
-- `main` has no module system: highlighting/indent are enabled per-buffer.
local LANGS = {
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
	"latex",
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

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		{
			"windwp/nvim-ts-autotag",
			-- `main` dropped the module system, so autotag configures itself now
			-- instead of via a treesitter `autotag = {}` table.
			event = { "BufReadPre", "BufNewFile" },
			opts = {},
		},
	},
	config = function()
		require("nvim-treesitter").setup({})

		-- no-op for parsers already present; async, so it never blocks startup
		require("nvim-treesitter").install(LANGS)

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("anirudh_treesitter", { clear = true }),
			callback = function(ev)
				local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
				if not lang then
					return
				end
				-- pcall: language.add() throws when no parser is installed yet
				local ok = pcall(vim.treesitter.language.add, lang)
				if not ok then
					return
				end
				if not pcall(vim.treesitter.start, ev.buf, lang) then
					return
				end
				-- treesitter is now highlighting this buffer, so the legacy regex
				-- syntax engine is pure duplicated work -- it re-scans on every
				-- redraw and costs ~40ms per buffer just to source.
				vim.bo[ev.buf].syntax = ""
				-- treesitter indent is still marked experimental upstream
				vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				-- native treesitter folding (replaces nvim-ufo)
				vim.wo[0][0].foldmethod = "expr"
				vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end,
		})

		-- ------------------------------------------------------------------
		-- incremental selection: `main` removed the module, so this is a small
		-- reimplementation of the <C-space> / <bs> keymaps from the old config.
		-- ------------------------------------------------------------------
		local stack = {}

		local function select_node(node)
			local srow, scol, erow, ecol = node:range()
			vim.fn.setpos("'<", { 0, srow + 1, scol + 1, 0 })
			vim.fn.setpos("'>", { 0, erow + 1, ecol, 0 })
			vim.cmd("normal! gv")
		end

		vim.keymap.set({ "n", "x" }, "<C-space>", function()
			local node
			if vim.tbl_isempty(stack) then
				node = vim.treesitter.get_node()
			else
				node = stack[#stack]:parent()
			end
			if not node then
				return
			end
			table.insert(stack, node)
			select_node(node)
		end, { desc = "Treesitter: expand selection" })

		vim.keymap.set("x", "<bs>", function()
			table.remove(stack)
			local node = stack[#stack]
			if node then
				select_node(node)
			end
		end, { desc = "Treesitter: shrink selection" })

		vim.api.nvim_create_autocmd("ModeChanged", {
			pattern = "[vV\x16]*:[^vV\x16]*",
			callback = function()
				stack = {}
			end,
		})
	end,
}
