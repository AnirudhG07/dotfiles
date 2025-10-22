return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {
			model = "claude-4-sonnet",
			window = {
				layout = "float",
				border = "rounded",
				title = "Copilot Chat",
				-- title_pos = "center",
				width = 0.6,
				height = 0.6,
				margin = { top = 2, right = 2, bottom = 2, left = 2 },
			},
			auto_insert_mode = true,
		},
		-- Use :CopilotChat to open the chat window
		cmd = { "CopilotChat", "CopilotChatOpen", "CopilotChatToggle" },
		keys = {
			{ "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
		},
	},

	-- Add Copilot.vim configuration
	{
		"github/copilot.vim",
		-- event = "InsertEnter",
		config = function()
			-- Tab configuration
			vim.g.copilot_no_tab_map = false
			vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { silent = false, expr = true })

			-- Additional settings
			vim.g.copilot_filetypes = {
				["*"] = true,
				["markdown"] = true,
			}
		end,
	},
}
