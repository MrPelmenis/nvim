return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        require("nvim-tree").setup({
            actions = {
                open_file = {
                    quit_on_open = true,  -- Close tree when file is opened
                },
            },
        })
        vim.keymap.set('n', '<C-b>', '<Cmd>NvimTreeFindFileToggle<CR>', { desc = "Toggle File Tree" })
    end
}

