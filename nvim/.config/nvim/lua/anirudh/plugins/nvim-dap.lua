return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui", -- UI for nvim-dap
		"nvim-neotest/nvim-nio", -- Test runner for nvim-dap
		"mfussenegger/nvim-dap-python", -- Python support for nvim-dap
		"leoluz/nvim-dap-go", -- Go support for nvim-dap
		"theHamsta/nvim-dap-virtual-text", -- Virtual text for nvim-dap
	},
	config = function()
		local dap, dapui = require("dap"), require("dapui")
		dapui.setup()

		-- Setup each nvim-dap
		require("dap-go").setup()
		require("dap-python").setup("python3")

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debugger Toggle breakpoint" })
		vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debugger Open REP" })
		vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debugger Continue" })
		vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Debugger Step over" })
		vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debugger Step into" })
		vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Debugger Step out" })
		vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debugger Open REPL" })
		vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debugger Run last" })
		vim.keymap.set("n", "<leader>dd", dap.disconnect, { desc = "Debugger Disconnect" })

		vim.keymap.set("n", "<leader>dO", dapui.open, { desc = "Open DAP UI" })
	end,
}
