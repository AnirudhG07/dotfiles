return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"andrew-george/telescope-themes",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
			},
		})

		telescope.load_extension("fzf")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
		keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope registers<cr>", { desc = "Fuzzy find registers" })
		keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fs", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
		keymap.set(
			"n",
			"<leader>fb",
			"<cmd>Telescope buffers<cr>",
			{ desc = "Lists open buffers in current neovim instance" }
		)
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope colorscheme<cr>", { desc = "Find themes" })

		local builtin_schemes = require("telescope._extensions.themes").builtin_schemes

		require("telescope").setup({
			extensions = {
				themes = {
					-- you can add regular telescope config
					-- that you want to apply on this picker only
					layout_config = {
						horizontal = {
							width = 0.8,
							height = 0.7,
						},
					},

					-- extension specific config

					-- (boolean) -> show/hide previewer window
					enable_previewer = true,

					-- (boolean) -> enable/disable live preview
					enable_live_preview = false,

					-- all builtin themes are ignored by default
					-- (list) -> provide table of theme names to overwrite builtins list
					ignore = { "default", "desert", "elflord", "habamax" },
					-- OR
					-- extend the required `builtin_schemes` list to ignore other
					-- schemes in addition to builtin schemes
					ignore = vim.list_extend(builtin_schemes, { "embark" }),

					-- (table)
					-- (boolean) ignore -> toggle ignore light themes
					-- (list) keywords -> list of keywords that would identify as light theme
					light_themes = {
						ignore = true,
						keywords = { "light", "day", "frappe" },
					},

					-- (table)
					-- (boolean) ignore -> toggle ignore dark themes
					-- (list) keywords -> list of keywords that would identify as dark theme
					dark_themes = {
						ignore = false,
						keywords = { "dark", "night", "black" },
					},

					persist = {
						-- enable persisting last theme choice
						enabled = true,

						-- override path to file that execute colorscheme command
						path = vim.fn.stdpath("config") .. "/lua/colorscheme.lua",
					},
					mappings = {
						-- for people used to other mappings
						down = "<C-n>",
						up = "<C-p>",
						accept = "<C-y>",
					},
				},
			},
		})
	end,
}
