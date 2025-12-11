return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local builtin = require("telescope.builtin")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Custom action to open file in new tab, jump to existing tab, 
        -- and jump to the correct line/column from search results.
        local function open_in_new_tab(prompt_bufnr)
            local entry = action_state.get_selected_entry()

            if not entry then
                return
            end

            -- 1. Extract file path and location info
            local file_path = entry.path or entry.value or entry.filename

            -- Fallback for entries without a direct path field
            if not file_path and entry[1] then
                local picker = action_state.get_current_picker(prompt_bufnr)
                local cwd = picker and picker.cwd or vim.fn.getcwd()
                file_path = vim.fn.fnamemodify(cwd .. "/" .. entry[1], ":p")
            end

            if not file_path then
                actions.select_default(prompt_bufnr)
                return
            end

            -- Location data from live_grep/grep_string results
            local line_num = entry.lnum
            local col_num = entry.col
            local normalized_new = vim.fn.fnamemodify(file_path, ':p')

            local found_tab = nil
            local found_win = nil

            -- 2. Check if the file is already open and find its tab/window
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local buf_name = vim.api.nvim_buf_get_name(buf)

                    if buf_name ~= "" then
                        local normalized_buf = vim.fn.fnamemodify(buf_name, ':p')
                        if normalized_buf == normalized_new then
                            found_tab = tab
                            found_win = win
                            break
                        end
                    end
                end
                if found_tab then break end
            end

            actions.close(prompt_bufnr) -- Close Telescope window

            if found_tab then
                -- 3a. File already open: Jump to existing tab/window and position cursor
                vim.api.nvim_set_current_tabpage(found_tab)
                vim.api.nvim_set_current_win(found_win)

                vim.defer_fn(function()
                    -- Jump to the line and column
                    if line_num and type(line_num) == 'number' then
                        vim.cmd('normal! ' .. line_num .. 'G')
                        if col_num and type(col_num) == 'number' then
                            vim.cmd('normal! ' .. col_num .. '|zt')
                        else
                            vim.cmd('normal! zz')
                        end
                    end
                end, 0)

            else
                -- 3b. File not open: Open in new tab and position cursor
                
                -- FIX: Use +line syntax instead of prepending the number to the command
                local cmd = 'tabnew'
                
                if line_num and type(line_num) == 'number' then
                    cmd = cmd .. ' +' .. line_num
                end
                
                cmd = cmd .. ' ' .. vim.fn.fnameescape(file_path)

                -- Execute the command
                vim.defer_fn(function()
                    vim.cmd(cmd)

                    -- Jump to column after the file/tab is created and centered
                    if col_num and type(col_num) == 'number' then
                        vim.cmd('normal! ' .. col_num .. '|zt')
                    else
                        -- If we only had a line number (from the +cmd), ensure it is centered
                        if line_num then
                            vim.cmd('normal! zz')
                        end
                    end
                end, 10)
            end
        end

        -- Configure telescope with custom action
        require("telescope").setup({
            defaults = {
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        preview_width = 0.65, -- increase preview
                        results_width = 0.35, -- decrease results list
                    },
                    width = 0.98,  -- almost full screen
                    height = 0.90, -- nice large window
                },
                mappings = {
                    i = {
                        ["<CR>"] = open_in_new_tab,
                    },
                    n = {
                        ["<CR>"] = open_in_new_tab,
                    },
                },
            },
        })

        -- Keymaps
        vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Telescope find files" })
        vim.keymap.set('n', '<A-f>', builtin.live_grep, { desc = "Telescope live grep" })
    end
}
