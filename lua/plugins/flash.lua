return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        -- Enable autojump globally or inside specific modes
        jump = {
            autojump = true,
        },
        modes = {
            -- If you are using enhanced f/t motions or char mode with jump labels:
            char = {
                jump_labels = true,
                jump = { autojump = true },
            },
        },
    },
    keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
    },
}
