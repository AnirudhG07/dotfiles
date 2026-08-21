return {
	-- mason moved orgs at v2; williamboman/* still redirects but the canonical
	-- name avoids a surprise when the redirect eventually goes away.
	"mason-org/mason.nvim",
	lazy = false,
	dependencies = {
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},

	config = function()
		-- mason.setup() must run before mason-lspconfig.setup()
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		require("mason-lspconfig").setup({
			-- list of servers for mason to install
			ensure_installed = {
				"html",
				"lua_ls",
				-- "jdtls",
				-- "rust_analyzer",
			},
			-- mason-lspconfig v2 auto-enables every installed server via
			-- vim.lsp.enable(). Servers owned by another plugin must be excluded
			-- or you get two clients attached to the same buffer.
			automatic_enable = {
				exclude = {
					"rust_analyzer", -- owned by rustaceanvim
					"jdtls", -- would be owned by nvim-java
					"stylua", -- formatter; already run via conform.nvim
				},
			},
		})

		require("mason-tool-installer").setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"ruff", -- python linter
				"tinymist", -- typst linter
				"isort", -- python import formatter
				"tree-sitter-cli", -- required by nvim-treesitter `main` to install parsers
				-- "gopls", -- go formatter
				-- "goimports",
				-- "rust-analyzer", -- rust formatter
			},
		})
	end,
}
