return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            size = 15,
            direction = "horizontal",
            close_on_exit = true,
            auto_scroll = true,
            start_in_insert = true,
            persist_size = true,
            persist_mode = true,
        })

        -- Track terminal IDs
        local next_terminal_id = 0
        local current_visible_terminal = nil
        
        -- Check if any terminal is open
        local function any_terminal_open()
            local wins = vim.api.nvim_list_wins()
            for _, win in ipairs(wins) do
                local buf = vim.api.nvim_win_get_buf(win)
                local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
                if buf_type == 'terminal' then
                    return true
                end
            end
            return false
        end

        -- Get the current terminal ID if in a terminal
        local function get_current_terminal_id()
            local buf_type = vim.api.nvim_buf_get_option(0, 'buftype')
            if buf_type == 'terminal' then
                local buf = vim.api.nvim_get_current_buf()
                return vim.b[buf].toggle_number
            end
            return nil
        end

        -- Check if a specific terminal is currently open
        local function is_terminal_open(term_id)
            local wins = vim.api.nvim_list_wins()
            for _, win in ipairs(wins) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_get_option(buf, 'buftype') == 'terminal' then
                    local buf_term_id = vim.b[buf].toggle_number
                    if buf_term_id == term_id then
                        return true, win
                    end
                end
            end
            return false, nil
        end

        -- Switch to a specific terminal (closes others, opens the target)
        local function switch_to_terminal(term_id)
            local is_open, win_id = is_terminal_open(term_id)
            
            -- Close current terminal if a different one is open
            if current_visible_terminal and current_visible_terminal ~= term_id then
                local other_open, _ = is_terminal_open(current_visible_terminal)
                if other_open then
                    vim.cmd(current_visible_terminal .. 'ToggleTerm')
                end
            end
            
            -- If target terminal is already open, just focus it
            if is_open and win_id then
                vim.api.nvim_set_current_win(win_id)
            else
                -- Open the target terminal
                vim.cmd(term_id .. 'ToggleTerm')
            end
            
            current_visible_terminal = term_id
            
            vim.defer_fn(function()
                vim.cmd('startinsert')
            end, 50)
        end

        -- Ctrl+/: Open a new terminal
        vim.keymap.set({'n', 'i', 't'}, '<C-_>', function()
            next_terminal_id = next_terminal_id + 1
            switch_to_terminal(next_terminal_id)
        end, { noremap = true, silent = true, desc = "Open new terminal" })

        -- Ctrl+t: Focus terminal (from editor)
        vim.keymap.set({'n', 'i'}, '<C-t>', function()
            -- Open terminal 1 or the last visible terminal
            if next_terminal_id == 0 then
                next_terminal_id = 1
            end
            local term_to_open = current_visible_terminal or 1
            switch_to_terminal(term_to_open)
        end, { noremap = true, silent = true, desc = "Focus terminal" })

        -- Terminal mode Ctrl+t: Hide all terminals
        vim.keymap.set('t', '<C-t>', function()
            vim.cmd('ToggleTermToggleAll')
            current_visible_terminal = nil
        end, { noremap = true, silent = true, desc = "Hide terminals" })

        -- Ctrl+e: Focus editor (go back to previous window)
        vim.keymap.set('t', '<C-e>', '<C-\\><C-n><Cmd>wincmd p<CR>', { noremap = true, silent = true, desc = "Focus editor" })
        vim.keymap.set('n', '<C-e>', '<Cmd>wincmd p<CR>', { noremap = true, silent = true, desc = "Focus previous window" })
        vim.keymap.set('i', '<C-e>', '<Esc><Cmd>wincmd p<CR>', { noremap = true, silent = true, desc = "Focus previous window" })

        -- Ctrl+w: Close current terminal permanently
        vim.keymap.set('t', '<C-w>', function()
            local term_id = get_current_terminal_id()
            if term_id then
                -- Use ToggleTerm command to properly close
                vim.cmd(term_id .. 'ToggleTerm')
                current_visible_terminal = nil
                -- Then delete the buffer
                vim.defer_fn(function()
                    pcall(vim.cmd, 'bwipeout! term://*toggleterm#' .. term_id)
                end, 100)
            end
        end, { noremap = true, silent = true, desc = "Close terminal" })

        -- Ctrl+PageDown: Next terminal
        vim.keymap.set({'n', 't', 'i'}, '<C-PageDown>', function()
            local current_id = get_current_terminal_id()
            if not current_id then
                current_id = current_visible_terminal or 0
            end
            
            local next_id = current_id + 1
            if next_id > next_terminal_id then
                next_id = 1
            end
            
            if next_id > 0 then
                switch_to_terminal(next_id)
            end
        end, { noremap = true, silent = true, desc = "Next terminal" })

        -- Ctrl+PageUp: Previous terminal
        vim.keymap.set({'n', 't', 'i'}, '<C-PageUp>', function()
            local current_id = get_current_terminal_id()
            if not current_id then
                current_id = current_visible_terminal or 2
            end
            
            local prev_id = current_id - 1
            if prev_id < 1 then
                prev_id = next_terminal_id
            end
            
            if prev_id > 0 then
                switch_to_terminal(prev_id)
            end
        end, { noremap = true, silent = true, desc = "Previous terminal" })

        -- Ctrl+n: Exit terminal mode (to normal mode)
        vim.keymap.set('t', '<C-n>', [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Exit terminal mode" })

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
