return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",

		-- Languages
		"nvim-neotest/neotest-python",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-python"),
				require("rustaceanvim.neotest"),
			},
		})

		-- Keymaps
		local neotest = require("neotest")
		local keymap = vim.keymap.set
		keymap("n", "<leader>nr", neotest.run.run, { desc = "Run nearest test" })
		keymap("n", "<leader>ns", neotest.summary.toggle, { desc = "Toggle test summary" })
		keymap("n", "<leader>nS", neotest.run.stop, { desc = "Stop running tests" })
		keymap("n", "<leader>nO", neotest.output.open, { desc = "Open test output" })
		keymap("n", "<leader>nt", neotest.run.attach, { desc = "Attach to test" })
		keymap("n", "<leader>na", function()
			neotest.run.run(vim.fn.expand("%:p"))
		end, { desc = "Run all tests in file" })
	end,
}
