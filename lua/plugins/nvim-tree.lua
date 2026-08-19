return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        require("nvim-tree").setup({
            actions = {
                open_file = {
                    quit_on_open = true,
                    window_picker = { enable = false },
                },
            },
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                local opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }

                -- default mappings
                api.config.mappings.default_on_attach(bufnr)

                -- override <CR> to handle drop for files, and edit for directories
                vim.keymap.set('n', '<CR>', function()
                    local node = api.tree.get_node_under_cursor()

                    if node.type == "directory" then
                        -- Expand/Collapse directory
                        api.node.open.edit(node)
                    else
                        -- Jump to the tab if open, otherwise open it
                        api.node.open.drop(node)
                    end
                end, opts)
            end,
        })

        vim.keymap.set('n', '<C-b>', '<Cmd>NvimTreeFindFileToggle<CR>', { desc = "Toggle File Tree" })

        -- tab navigation
    end
}
