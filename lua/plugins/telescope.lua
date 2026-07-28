return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local builtin = require("telescope.builtin")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Close Telescope without letting a stray keycode switch tabs
        local function safe_close(prompt_bufnr)
            local tab = vim.api.nvim_get_current_tabpage()
            actions.close(prompt_bufnr)
            vim.defer_fn(function()
                if vim.api.nvim_tabpage_is_valid(tab) then
                    pcall(vim.api.nvim_set_current_tabpage, tab)
                end
            end, 70) -- must be > ttimeoutlen (50)
        end

        -- Open in new tab, or jump to existing tab, at the right line/col
        local function open_in_new_tab(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            if not entry then
                actions.close(prompt_bufnr)
                return
            end

            local file_path = entry.path or entry.value or entry.filename
            if not file_path and entry[1] then
                local picker = action_state.get_current_picker(prompt_bufnr)
                local cwd = picker and picker.cwd or vim.fn.getcwd()
                file_path = vim.fn.fnamemodify(cwd .. "/" .. entry[1], ":p")
            end
            if not file_path then
                actions.select_default(prompt_bufnr)
                return
            end

            local line_num = entry.lnum
            local col_num = entry.col
            local normalized_new = vim.fn.fnamemodify(file_path, ':p')
            local found_tab, found_win = nil, nil

            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name ~= "" then
                        if vim.fn.fnamemodify(buf_name, ':p') == normalized_new then
                            found_tab, found_win = tab, win
                            break
                        end
                    end
                end
                if found_tab then break end
            end

            actions.close(prompt_bufnr)

            if found_tab then
                vim.api.nvim_set_current_tabpage(found_tab)
                vim.api.nvim_set_current_win(found_win)
                vim.defer_fn(function()
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
                local cmd = 'tabnew'
                if line_num and type(line_num) == 'number' then
                    cmd = cmd .. ' +' .. line_num
                end
                cmd = cmd .. ' ' .. vim.fn.fnameescape(file_path)
                vim.defer_fn(function()
                    vim.cmd(cmd)
                    if col_num and type(col_num) == 'number' then
                        vim.cmd('normal! ' .. col_num .. '|zt')
                    elseif line_num then
                        vim.cmd('normal! zz')
                    end
                end, 10)
            end
        end

        require("telescope").setup({
            defaults = {
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        preview_width = 0.65,
                        results_width = 0.35,
                    },
                    width = 0.98,
                    height = 0.90,
                },
                mappings = {
                    i = {
                        ["<CR>"]  = open_in_new_tab,
                        ["<Esc>"] = safe_close,
                    },
                    n = {
                        ["<CR>"]  = open_in_new_tab,
                        ["<Esc>"] = safe_close,
                    },
                },
            },
        })

        vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Telescope find files" })
        vim.keymap.set('n', '<A-p>', builtin.live_grep, { desc = "Telescope live grep" })
    end
}
