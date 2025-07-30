return {
	"folke/snacks.nvim",
	opts = {
		picker = {
			sources = {
				explorer = {
					win = {
						list = {
							keys = {
								["<BS>"] = "explorer_up",
								["l"] = "confirm",
								["h"] = "explorer_close", -- close directory
								["a"] = "explorer_add",
								["d"] = "explorer_del",
								["r"] = "explorer_rename",
								["c"] = "explorer_copy",
								["m"] = "explorer_move",
								["o"] = "", -- "explorer_open", -- open with system application
								["P"] = "toggle_preview",
								["y"] = { "explorer_yank", mode = { "n", "x" } },
								["p"] = "explorer_paste",
								["u"] = "explorer_update",
								["<c-c>"] = "tcd",
								["<leader>/"] = "picker_grep",
								["<c-t>"] = "terminal",
								["."] = "explorer_focus",
								["I"] = "toggle_ignored",
								["H"] = "toggle_hidden",
								["Z"] = "explorer_close_all",
								["]g"] = "explorer_git_next",
								["[g"] = "explorer_git_prev",
								["]d"] = "explorer_diagnostic_next",
								["[d"] = "explorer_diagnostic_prev",
								["]w"] = "explorer_warn_next",
								["[w"] = "explorer_warn_prev",
								["]e"] = "explorer_error_next",
								["[e"] = "explorer_error_prev",
							},
						},
					},
					actions = {
						explorer_rename = function(picker, item, action) --[[Override]]
							local input = vim.ui.input
							vim.ui.input = function(opts, on_confirm) ---@diagnostic disable-line
								local size = picker.list.win:size()
								opts.win = {
									border = "single",
									relative = "editor",
									row = -3,
									col = 0,
									width = size.width - 2 --[[border]],
								}
								return input(opts, on_confirm)
							end
							-- NOTE: Rename action
							require("snacks.explorer.actions").actions.explorer_rename(picker, item, action)
							vim.ui.input = input
						end,
					},
				},
			},
		},
	},
}
