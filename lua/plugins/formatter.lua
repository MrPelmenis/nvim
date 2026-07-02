return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        -- Define formatters per language
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "black" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            html = { "prettierd", "prettier", stop_after_first = true },
            css = { "prettierd", "prettier", stop_after_first = true },
            rust = { "rustfmt" },
        },
        -- Optional: Setup format-on-save automatically
        format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
        },
    },
}
