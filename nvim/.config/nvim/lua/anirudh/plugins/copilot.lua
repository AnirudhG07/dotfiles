return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {
			-- "auto": GitHub picks the current default model per request, so nothing goes stale when
			-- Copilot retires a model (the plugin's built-in default gpt-5-mini no longer exists).
			-- Pick another for one chat with :CopilotChatModels, or $model in the prompt.
			model = "auto",
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
