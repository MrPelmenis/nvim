return {
    "m4xshen/autoclose.nvim",
    config = function()
        require("autoclose").setup({
            keys = {
                ["("] = { escape = false, close = true, pair = "()" },
                ["["] = { escape = false, close = true, pair = "[]" },
                ["{"] = { escape = false, close = true, pair = "{}" },
                [">"] = { escape = false, close = true, pair = "<>" },
                ['"'] = { escape = true, close = true, pair = '""' },
                ["'"] = { escape = true, close = true, pair = "''" },
                ["`"] = { escape = true, close = true, pair = "``" },
            },
            options = {
                disabled_filetypes = { "text", "markdown" },
                disable_when_touch = false,
            },
        })
    end,
}

