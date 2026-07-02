return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
        indent = {
            char = "│", -- The character used for the vertical line
        },
        scope = {
            enabled = true, -- Highlights the current nesting level you are in
            show_start = false,
            show_end = false,
        },
    },
}
