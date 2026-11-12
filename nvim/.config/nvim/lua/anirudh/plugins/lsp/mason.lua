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

		-- what to install lives in lua/anirudh/core/tools.lua (core: Python + C/C++ servers)
		-- and lua/anirudh/machine.lua (this machine's extras); mason-tool-installer does it all.
		local tools = require("anirudh.core.tools")

		require("mason-lspconfig").setup({
			ensure_installed = {},
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

		-- No tree-sitter-cli here: mason's copy is the GitHub binary, which needs glibc 2.39 and
		-- would shadow the working one setup.sh puts in ~/.local/bin (mason's bin dir comes first).
		require("mason-tool-installer").setup({
			ensure_installed = tools.mason(),
		})

		-- core servers the system already provides (apt clangd, uv's ruff): mason-lspconfig only
		-- auto-enables servers mason installed, so turn these on by name
		vim.lsp.enable(tools.system_servers())
	end,
}
