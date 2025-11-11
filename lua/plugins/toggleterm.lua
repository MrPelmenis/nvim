return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        local Terminal = require("toggleterm.terminal").Terminal
        require("toggleterm").setup({
            size = 10,
            direction = "horizontal",
            close_on_exit = true,
            auto_scroll = true,
            start_in_insert = true,
            persist_size = true,
        })

        -- Store terminal object
        local terminals = {}
        local function get_terminal(id)
            if not terminals[id] then
                terminals[id] = Terminal:new({
                    id = id,
                    direction = "horizontal",
                    close_on_exit = true,
                    hidden = false,
                })
            end
            return terminals[id]
        end

        -- Horizontal terminal toggle (Ctrl+t)
        vim.keymap.set('n', '<C-t>', function()
            local term = get_terminal(1)
            if term:is_open() then
                if vim.api.nvim_get_current_buf() == term.bufnr then
                    term:toggle()
                else
                    term:focus()
                    -- Always enter insert mode when focusing terminal
                    vim.defer_fn(function()
                        vim.cmd('startinsert')
                    end, 10)
                end
            else
                term:open()
                -- Always enter insert mode when opening terminal
                vim.defer_fn(function()
                    vim.cmd('startinsert')
                end, 10)
            end
        end, { noremap = true, silent = true })

        -- Ctrl+T in terminal mode: toggle terminal off
        vim.keymap.set('t', '<C-t>', function()
            local term = get_terminal(1)
            if term:is_open() then
                term:toggle()
            end
        end, { noremap = true, silent = true })

        -- Terminal keymaps
        vim.keymap.set('t', '<C-n>', [[<C-\><C-n>]], { noremap = true, silent = true })
        vim.keymap.set('t', '<C-e>', '<C-\\><C-n><Cmd>wincmd p<CR>', { noremap = true, silent = true })
        vim.keymap.set('n', '<C-e>', [[<Cmd>wincmd p<CR>]], { noremap = true, silent = true })

        -- Autocommand to always enter insert mode when entering terminal buffer
        vim.api.nvim_create_autocmd('TermOpen', {
            callback = function()
                vim.cmd('startinsert')
            end,
        })

        -- Also ensure insert mode when switching to terminal buffer
        vim.api.nvim_create_autocmd('BufEnter', {
            callback = function()
               local buf_type = vim.api.nvim_buf_get_option(0, 'buftype')
                if buf_type == 'terminal' and vim.api.nvim_get_mode().mode ~= 'i' then
                    vim.cmd('startinsert')
                end
            end,
        })
    end
}

