return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local builtin = require("telescope.builtin")
        
        -- Custom action to open file in new tab (or do nothing if same file)
        local function open_in_new_tab(prompt_bufnr)
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local entry = action_state.get_selected_entry()
            
            if not entry then
                return
            end
            
            -- Get file path - Telescope entries have the path in entry.path
            local file_path = entry.path
            if not file_path then
                -- Try to get from entry value or filename
                file_path = entry.value or entry.filename
            end
            if not file_path and entry[1] then
                -- Fallback: construct path from cwd and filename
                local picker = action_state.get_current_picker(prompt_bufnr)
                local cwd = picker and picker.cwd
                if not cwd then
                    cwd = vim.fn.getcwd()
                end
                file_path = vim.fn.fnamemodify(cwd .. "/" .. entry[1], ":p")
            end
            
            if not file_path then
                -- If we still don't have a path, just use default action
                actions.select_default(prompt_bufnr)
                return
            end
            
            -- Normalize the new file path
            local normalized_new = vim.fn.fnamemodify(file_path, ':p')
            
            -- Check if file is already open in any tab
            local file_already_open = false
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name ~= "" then
                        local normalized_buf = vim.fn.fnamemodify(buf_name, ':p')
                        if normalized_buf == normalized_new then
                            file_already_open = true
                            break
                        end
                    end
                end
                if file_already_open then break end
            end
            
            if file_already_open then
                -- Same file already open, just close telescope
                actions.close(prompt_bufnr)
            else
                -- Different file, open in new tab
                actions.close(prompt_bufnr)
                -- Use vim.cmd with proper escaping
          vim.defer_fn(function()
                    vim.cmd('tabnew ' .. vim.fn.fnameescape(file_path))
                end, 10)
            end
        end
        
        -- Configure telescope with custom action
        require("telescope").setup({
            defaults = {
                 layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = {
                            preview_width = 0.65,  -- increase preview
                            results_width = 0.35,  -- decrease results list
                        },
                        width = 0.98,  -- optional: almost full screen
                        height = 0.90, -- optional: nice large window
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
        
        vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Telescope find files" })
        vim.keymap.set('n', '<A-f>', builtin.live_grep, { desc = "Telescope live grep" })
        
        -- Tab navigation is now handled in toggleterm.lua to avoid conflicts
        -- The keybinds check if we're in a terminal and route accordingly
    end
}

