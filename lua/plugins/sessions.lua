-- plugins/sessions.lua

return {
    "rmagatti/auto-session",
    config = function()
        local session_dir = vim.fn.stdpath("data") .. "/sessions/"

        -- ==========================
        -- Auto-session setup
        -- ==========================
        require("auto-session").setup {
            log_level = "info",
            auto_session_enable_last_session = true,
            auto_session_root_dir = session_dir,
            auto_session_enabled = true,
            auto_save_enabled = true,
            auto_restore_enabled = true,
            bypass_session_save_file_types = { "gitcommit", "fugitive", "packer" },
        }

        -- ==========================
        -- Terminal persistence
        -- ==========================
        local term_state_file = session_dir .. "term_state.lua"

        local function save_terminals()
            local terminals = {}
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buf].buftype == "terminal" then
                    local cwd = vim.fn.getcwd(-1, buf)
                    local cmd = vim.b[buf].term_title or "" -- optional command
                    table.insert(terminals, { cwd = cwd, cmd = cmd })
                end
            end
            local f = io.open(term_state_file, "w")
            if f then
                f:write("return " .. vim.inspect(terminals))
                f:close()
            end
        end

        vim.api.nvim_create_autocmd("VimLeavePre", { callback = save_terminals })

        local function restore_terminals()
            local f = loadfile(term_state_file)
            if not f then return end
            local terminals = f()
            for _, t in ipairs(terminals) do
                vim.cmd("tabnew")
                vim.cmd("lcd " .. t.cwd)
                vim.cmd("terminal")
                -- Optional: send last command to terminal
                -- vim.api.nvim_chan_send(vim.b.terminal_job_id, t.cmd .. "\n")
            end
        end

        vim.api.nvim_create_autocmd("VimEnter", { callback = restore_terminals })

        -- ==========================
        -- Optional: auto-save session on idle
        -- ==========================
        vim.cmd([[
          autocmd CursorHold,CursorHoldI * mksession! ]] .. session_dir .. [[last-session.vim
        ]])
    end
}

