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

                -- override <CR> to handle both files and directories properly
                vim.keymap.set('n', '<CR>', function()
                    local node = api.tree.get_node_under_cursor()
                    
                    -- FILE LOGIC
                    if node.type == "file" then
                        -- check if file is already open in a tab
                        for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
                            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
                                local buf = vim.api.nvim_win_get_buf(win)
                                if vim.api.nvim_buf_get_name(buf) == node.absolute_path then
                                    vim.api.nvim_set_current_tabpage(tabpage)
                                    api.tree.close()
                                    return
                                end
                            end
                        end
                        -- not found, open in new tab
                        api.node.open.tab(node)

                    -- DIRECTORY LOGIC
                    elseif node.type == "directory" then
                        -- Open, close, or enter the directory normally
                        api.node.open.edit(node)
                    end
                end, opts)
            end,
        })

        vim.keymap.set('n', '<C-b>', '<Cmd>NvimTreeFindFileToggle<CR>', { desc = "Toggle File Tree" })

        -- tab navigation
    end
}
