return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		-- import comment plugin safely
		local comment = require("Comment")

		local ts_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
		local ft = require("Comment.ft")

		comment.setup({
			-- ts-context-commentstring handles embedded languages (tsx, jsx, svelte, html, vue...).
			-- When it has no answer (returns nil), never fall through to Comment.nvim's own
			-- treesitter lookup: on Neovim >= 0.11 get_parser() returns nil instead of erroring
			-- for buffers without a parser (cuda, any ft not installed) and Comment.nvim
			-- (unmaintained since 2024) crashes indexing it. Use its filetype table, then the
			-- buffer's 'commentstring', instead.
			pre_hook = function(ctx)
				local cs = ts_hook(ctx)
				if cs then
					return cs
				end
				cs = ft.get(vim.bo.filetype, ctx.ctype)
				if cs then
					return cs
				end
				return vim.bo.commentstring ~= "" and vim.bo.commentstring or nil
			end,
		})
	end,
}
