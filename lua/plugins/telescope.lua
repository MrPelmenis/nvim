return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local builtin = require("telescope.builtin")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Custom tab-drop action using Neovim's native `:tab drop`
        local function select_tab_drop(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not entry then return end

            local file_path = entry.path or entry.filename or entry.value
            if not file_path then return end

            local lnum = entry.lnum and (" +" .. entry.lnum) or ""
            vim.cmd("tab drop" .. lnum .. " " .. vim.fn.fnameescape(file_path))

            if entry.col then
                pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum or 1, entry.col - 1 })
            end
        end

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
                        ["<CR>"]  = select_tab_drop,
                        ["<Esc>"] = safe_close,
                    },
                    n = {
                        ["<CR>"]  = select_tab_drop,
                        ["<Esc>"] = safe_close,
                    },
                },
            },
        })

        vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Telescope find files" })
        vim.keymap.set('n', '<A-p>', builtin.live_grep, { desc = "Telescope live grep" })
    end
}
