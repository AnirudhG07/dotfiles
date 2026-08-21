return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		-- neodev.nvim is archived; lazydev is its successor for Neovim >= 0.10
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
	},
	config = function()
		local keymap = vim.keymap -- for conciseness

		vim.diagnostic.config({
			virtual_text = {
				-- source = "always",  -- Or "if_many"
				prefix = "■", -- Could be '■', '▎', 'x', '●'
			},
			severity_sort = true,
			float = {
				source = "if_many", -- Or "if_many"
			},
			-- signs.text is keyed by severity. The old loop passed a bare string
			-- four times, so every severity ended up with the last icon.
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
				numhl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
					[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
					[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
				},
			},
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- inlay hints are per-buffer; enabling them globally in config()
				-- ran before any client had attached
				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				if client and client:supports_method("textDocument/inlayHint") then
					vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
				end

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", "<cmd>LspRestart<CR>", opts)
			end,
		})

		-- ------------------------------------------------------------------
		-- Server configuration.
		--
		-- mason-lspconfig v2 REMOVED the `handlers` option, so the old
		-- `mason_lspconfig.setup({ handlers = {...} })` block was dead code --
		-- none of it ran. Servers are now configured with vim.lsp.config() and
		-- enabled by mason-lspconfig's `automatic_enable` (see mason.lua).
		-- ------------------------------------------------------------------

		-- applies to every server
		vim.lsp.config("*", {
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					-- make the language server recognize the "vim" global
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})

		vim.lsp.config("ruff", {
			-- defer hover to pyright
			on_attach = function(client)
				client.server_capabilities.hoverProvider = false
			end,
			init_options = {
				settings = {
					-- Any extra CLI arguments for `ruff` go here.
					args = {},
				},
			},
		})

		vim.lsp.config("ty", {
			on_attach = function(client)
				client.server_capabilities.hoverProvider = false
			end,
			init_options = {
				settings = {
					-- Any extra CLI arguments for `ty` go here.
					args = {},
				},
			},
		})

		vim.lsp.config("gopls", {
			on_attach = function(client)
				client.server_capabilities.hoverProvider = false
			end,
		})

		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, ColumnLimit: 80}",
			},
		})
	end,
}
