return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "javascript", "typescript", "tsx",
                "html", "css", "scss",
                "c", "cpp", "cuda",
                "bash", "php", "lua",
                "make", "nginx",
                "vim", "python", "json", "yaml", "markdown",
            },
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

        -- Force Treesitter to highlight all currently loaded buffers
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                vim.cmd(string.format("buf %d | TSBufEnable highlight", buf))
            end
        end

        -- Ensure new buffers automatically attach Treesitter
        vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
            callback = function()
                vim.cmd("TSBufEnable highlight")
            end,
        })
    end
}

