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
            persist_mode = false,
            winbar = {
                enabled = true,
                name_formatter = function(term)
                    return string.format("Terminal #%d", term.id)
                end
            },
        })

        -- Track terminal IDs
        local next_terminal_id = 0
        local current_visible_terminal = nil
        local active_terminals = {} -- Keep track of which terminals exist
        
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

        -- Get next active terminal ID
        local function get_next_active_terminal(current_id)
            local sorted_ids = {}
            for id, _ in pairs(active_terminals) do
                if active_terminals[id] then
                    table.insert(sorted_ids, id)
                end
            end
            table.sort(sorted_ids)
            
            if #sorted_ids == 0 then return nil end
            
            for i, id in ipairs(sorted_ids) do
                if id > current_id then
                    return id
                end
            end
            return sorted_ids[1] -- Wrap around
        end

        -- Get previous active terminal ID
        local function get_prev_active_terminal(current_id)
            local sorted_ids = {}
            for id, _ in pairs(active_terminals) do
                if active_terminals[id] then
                    table.insert(sorted_ids, id)
                end
            end
            table.sort(sorted_ids)
            
            if #sorted_ids == 0 then return nil end
            
            for i = #sorted_ids, 1, -1 do
                if sorted_ids[i] < current_id then
                    return sorted_ids[i]
                end
            end
            return sorted_ids[#sorted_ids] -- Wrap around
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

        -- Helper function to check if we're in a terminal buffer
        local function is_terminal_buffer()
            return vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal'
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
            
            -- Always enter insert mode in terminal
            vim.defer_fn(function()
                if vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal' then
                    vim.cmd('startinsert')
                end
            end, 100)
        end

        -- Ctrl+/: Open a new terminal
        vim.keymap.set({'n', 'i', 't'}, '<C-_>', function()
            next_terminal_id = next_terminal_id + 1
            active_terminals[next_terminal_id] = true
            switch_to_terminal(next_terminal_id)
        end, { noremap = true, silent = true, desc = "Open new terminal" })

        -- Ctrl+t: Focus terminal (from editor)
        vim.keymap.set({'n', 'i'}, '<C-t>', function()
            -- Open terminal 1 or the last visible terminal
            if next_terminal_id == 0 then
                next_terminal_id = 1
                active_terminals[1] = true
            end
            local term_to_open = current_visible_terminal or 1
            -- Force-open in the **current tab**
            vim.cmd(term_to_open .. "ToggleTerm")
            if not active_terminals[term_to_open] then
                active_terminals[term_to_open] = true
            end
            switch_to_terminal(term_to_open)
        end, { noremap = true, silent = true, desc = "Focus terminal" })

        -- Terminal mode Ctrl+t: Hide all terminals
        vim.keymap.set('t', '<C-t>', function()
            vim.cmd('ToggleTermToggleAll')
            current_visible_terminal = nil
        end, { noremap = true, silent = true, desc = "Hide terminals" })

        -- Function to focus on the first non-terminal window (editor) in current tabpage
        local function focus_editor()
            -- Only look at windows in the current tabpage
            local tabpage = vim.api.nvim_get_current_tabpage()
            local wins = vim.api.nvim_tabpage_list_wins(tabpage)
            for _, win in ipairs(wins) do
                local buf = vim.api.nvim_win_get_buf(win)
                local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
                -- Find first window that's not a terminal
                if buf_type ~= 'terminal' then
                    vim.api.nvim_set_current_win(win)
                    return
                end
            end
        end

        -- Ctrl+e: Focus editor (go back to previous window)
        vim.keymap.set('t', '<C-e>', function()
            -- Exit terminal mode first
            local key = vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true)
            vim.api.nvim_feedkeys(key, 'n', false)
            vim.defer_fn(function()
                focus_editor()
            end, 10)
        end, { noremap = true, silent = true, desc = "Focus editor" })
        vim.keymap.set('n', '<C-e>', function()
            focus_editor()
        end, { noremap = true, silent = true, desc = "Focus editor" })
        vim.keymap.set('i', '<C-e>', function()
            vim.cmd('stopinsert')
            focus_editor()
        end, { noremap = true, silent = true, desc = "Focus editor" })

        -- Ctrl+w: Close current terminal (when in terminal) or Close tab (when in editor)
        vim.keymap.set({'n', 't', 'i'}, '<C-w>', function()
            if is_terminal_buffer() then
                -- Terminal close
                local term_id = get_current_terminal_id()
                if term_id then
                    -- Find another terminal to switch to BEFORE removing current one
                    local next_term = get_next_active_terminal(term_id)
                    if not next_term then
                        next_term = get_prev_active_terminal(term_id)
                    end
                    
                    -- Remove from active terminals
                    active_terminals[term_id] = nil
                    
                    -- If there's another terminal, switch to it FIRST before closing
                    if next_term then
                        -- Switch to next terminal first
                        switch_to_terminal(next_term)
                        -- Then close the old terminal in the background
                        vim.defer_fn(function()
                            pcall(vim.cmd, term_id .. 'ToggleTerm')
                            -- Delete the buffer
                            vim.defer_fn(function()
                                pcall(vim.cmd, 'bwipeout! term://*toggleterm#' .. term_id)
                            end, 100)
                        end, 150)
                    else
                        -- If no other terminals, close and go to editor
                        current_visible_terminal = nil
                        vim.cmd(term_id .. 'ToggleTerm')
                        -- Delete the buffer
                        vim.defer_fn(function()
                            pcall(vim.cmd, 'bwipeout! term://*toggleterm#' .. term_id)
                        end, 150)
                    end
                end
            else
                -- Tab close
                vim.cmd('tabclose')
            end
        end, { noremap = true, silent = true, desc = "Close terminal/tab" })

        -- Ctrl+PageDown: Next terminal (when in terminal) or Next tab (when in editor)
        vim.keymap.set({'n', 't', 'i'}, '<C-PageDown>', function()
            if is_terminal_buffer() then
                -- Terminal navigation
                local current_id = get_current_terminal_id()
                if not current_id then
                    current_id = current_visible_terminal or 0
                end
                
                local next_id = get_next_active_terminal(current_id)
                
                if next_id then
                    switch_to_terminal(next_id)
                end
            else
                -- Tab navigation
                vim.cmd('tabnext')
            end
        end, { noremap = true, silent = true, desc = "Next terminal/tab" })

        -- Ctrl+PageUp: Previous terminal (when in terminal) or Previous tab (when in editor)
        vim.keymap.set({'n', 't', 'i'}, '<C-PageUp>', function()
            if is_terminal_buffer() then
                -- Terminal navigation
                local current_id = get_current_terminal_id()
                if not current_id then
                    current_id = current_visible_terminal or 0
                end
                
                local prev_id = get_prev_active_terminal(current_id)
                
                if prev_id then
                    switch_to_terminal(prev_id)
                end
            else
                -- Tab navigation
                vim.cmd('tabprev')
            end
        end, { noremap = true, silent = true, desc = "Previous terminal/tab" })

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
                local mode = vim.api.nvim_get_mode().mode
                if buf_type == 'terminal' and mode ~= 't' and mode ~= 'i' then
                    vim.cmd('startinsert')
                end
            end,
        })
    end
}
