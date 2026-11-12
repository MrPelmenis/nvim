return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
        "windwp/nvim-ts-autotag",
        "nvim-treesitter/nvim-treesitter-context",
    },
    config = function()
        -- Modern parsers installation and setup
        require("nvim-treesitter").setup({
            ensure_installed = {
                "javascript", "typescript", "tsx",
                "html", "css", "scss",
                "c", "cpp", "cuda",
                "bash", "php", "lua",
                "make", "nginx",
                "vim", "python", "json", "yaml", "markdown", "markdown_inline",
            },
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
        })

        -- Setup autotag
        require("nvim-ts-autotag").setup({
            filetypes = { "html", "xml", "javascript", "javascriptreact", "typescript", "typescriptreact" },
        })
    end
}
