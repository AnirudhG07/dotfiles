return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			python = { "ruff" },
			-- rust = { "rust-analyzer" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		-- BufEnter fired try_lint() on every buffer switch, for every filetype.
		-- BufReadPost covers the initial lint; the rest run after edits.
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
