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

        -- Terminal selector floating window
        local selector_buf = nil
        local selector_win = nil

        local function close_selector()
            if selector_win and vim.api.nvim_win_is_valid(selector_win) then
                vim.api.nvim_win_close(selector_win, true)
                selector_win = nil
            end
            if selector_buf and vim.api.nvim_buf_is_valid(selector_buf) then
                vim.api.nvim_buf_delete(selector_buf, { force = true })
                selector_buf = nil
            end
        end

        local function show_terminal_selector()
            -- Close existing selector if open
            close_selector()

            -- Get sorted list of active terminals
            local sorted_ids = {}
            for id, _ in pairs(active_terminals) do
                if active_terminals[id] then
                    table.insert(sorted_ids, id)
                end
            end
            table.sort(sorted_ids)

            if #sorted_ids == 0 then
                return
            end

            -- Create buffer
            selector_buf = vim.api.nvim_create_buf(false, true)
            
            -- Build content
            local lines = { "┌─ Terminals ─┐" }
            local current_term = get_current_terminal_id() or current_visible_terminal
            
            for _, id in ipairs(sorted_ids) do
                local prefix = (id == current_term) and "▶ " or "  "
                table.insert(lines, prefix .. "Terminal " .. id)
            end
            table.insert(lines, "└─────────────┘")
            
            vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, lines)
            
            -- Calculate dimensions
            local width = 20
            local height = #lines
            local col = vim.o.columns - width - 2
            local row = 2
            
            -- Create window
            selector_win = vim.api.nvim_open_win(selector_buf, false, {
                relative = 'editor',
                width = width,
                height = height,
                col = col,
                row = row,
                style = 'minimal',
                border = 'rounded',
                focusable = false,
            })
            
            -- Set highlighting
            vim.api.nvim_buf_set_option(selector_buf, 'modifiable', false)
            vim.api.nvim_win_set_option(selector_win, 'winblend', 10)
            
            -- Highlight current terminal line
            local current_line = 0
            for i, id in ipairs(sorted_ids) do
                if id == current_term then
                    current_line = i
                    break
                end
            end
            
            if current_line > 0 then
                vim.api.nvim_buf_add_highlight(selector_buf, -1, 'Visual', current_line, 0, -1)
            end
        end

        -- Update selector when switching terminals
        local original_switch = switch_to_terminal
        switch_to_terminal = function(term_id)
            original_switch(term_id)
            if selector_win and vim.api.nvim_win_is_valid(selector_win) then
                show_terminal_selector()
            end
        end

        -- Ctrl+/: Open a new terminal
        vim.keymap.set({'n', 'i', 't'}, '<C-_>', function()
            next_terminal_id = next_terminal_id + 1
            active_terminals[next_terminal_id] = true
            switch_to_terminal(next_terminal_id)
        end, { noremap = true, silent = true, desc = "Open new terminal" })

        -- Ctrl+Shift+T: Toggle terminal selector
        vim.keymap.set({'n', 'i', 't'}, '<C-S-t>', function()
            if selector_win and vim.api.nvim_win_is_valid(selector_win) then
                close_selector()
            else
                show_terminal_selector()
            end
        end, { noremap = true, silent = true, desc = "Toggle terminal selector" })

        -- Ctrl+t: Focus terminal (from editor)
        vim.keymap.set({'n', 'i'}, '<C-t>', function()
            -- Open terminal 1 or the last visible terminal
            if next_terminal_id == 0 then
                next_terminal_id = 1
                active_terminals[1] = true
            end
            local term_to_open = current_visible_terminal or 1
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

        -- Ctrl+e: Focus editor (go back to previous window)
        vim.keymap.set('t', '<C-e>', '<C-\\><C-n><Cmd>wincmd p<CR>', { noremap = true, silent = true, desc = "Focus editor" })
        vim.keymap.set('n', '<C-e>', '<Cmd>wincmd p<CR>', { noremap = true, silent = true, desc = "Focus previous window" })
        vim.keymap.set('i', '<C-e>', '<Esc><Cmd>wincmd p<CR>', { noremap = true, silent = true, desc = "Focus previous window" })

        -- Ctrl+w: Close current terminal permanently
        vim.keymap.set('t', '<C-w>', function()
            local term_id = get_current_terminal_id()
            if term_id then
                -- Find another terminal to switch to BEFORE removing current one
                local next_term = get_next_active_terminal(term_id)
                if not next_term then
                    next_term = get_prev_active_terminal(term_id)
                end
                
                -- Remove from active terminals
                active_terminals[term_id] = nil
                
                -- Close current terminal
                vim.cmd(term_id .. 'ToggleTerm')
                
                -- Switch to another terminal (don't go to editor)
                if next_term then
                    vim.defer_fn(function()
                        switch_to_terminal(next_term)
                    end, 50)
                else
                    -- If no other terminals, stay in the terminal buffer area
                    current_visible_terminal = nil
                    close_selector()
                    vim.defer_fn(function()
                        vim.cmd('wincmd p')
                    end, 50)
                end
                
                -- Delete the buffer
                vim.defer_fn(function()
                    pcall(vim.cmd, 'bwipeout! term://*toggleterm#' .. term_id)
                end, 150)
            end
        end, { noremap = true, silent = true, desc = "Close terminal" })

        -- Ctrl+PageDown: Next terminal
        vim.keymap.set({'n', 't', 'i'}, '<C-PageDown>', function()
            local current_id = get_current_terminal_id()
            if not current_id then
                current_id = current_visible_terminal or 0
            end
            
            local next_id = get_next_active_terminal(current_id)
            
            if next_id then
                switch_to_terminal(next_id)
            end
        end, { noremap = true, silent = true, desc = "Next terminal" })

        -- Ctrl+PageUp: Previous terminal
        vim.keymap.set({'n', 't', 'i'}, '<C-PageUp>', function()
            local current_id = get_current_terminal_id()
            if not current_id then
                current_id = current_visible_terminal or 0
            end
            
            local prev_id = get_prev_active_terminal(current_id)
            
            if prev_id then
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
