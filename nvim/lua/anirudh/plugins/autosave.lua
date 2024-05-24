return {
    "0x00-ketsu/autosave.nvim",
    config = function()
        require("autosave").setup({
            enabled = false,
            events = { "InsertLeave", "TextChanged" },
            conditions = {
                exists = true,
                filetype_is_not = {},
                modifiable = true,
            },
            write_all_buffers = false,
            on_off_commands = true,
            clean_command_line_interval = 0,
            debounce_delay = 135,
        })
    end,
}
