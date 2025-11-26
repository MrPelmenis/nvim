return {
    "ojroques/nvim-osc52",
    config = function()
        require("osc52").setup({
            max_length = 0, -- Maximum length of selection. 0 for no limit.
            silent = false, -- Disable message on successful copy.
            trim_whitespace = true, -- Trim whitespace before copy.
        })

        -- Check if we're in an SSH session
        local function is_ssh_session()
            return vim.env.SSH_CLIENT ~= nil or vim.env.SSH_CONNECTION ~= nil
        end

        -- Check if system clipboard tools are available
        local function has_system_clipboard()
            return vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1 or vim.fn.executable("wl-copy") == 1
        end

        -- Use OSC52 if we're in SSH or if system clipboard isn't available
        if is_ssh_session() or not has_system_clipboard() then
            -- Override clipboard to use OSC52 for SSH
            -- This will automatically sync clipboard over SSH
            local function copy(lines, _)
                require("osc52").copy(table.concat(lines, "\n"))
            end

            local function paste()
                return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
            end

            -- Set up OSC52 as clipboard provider
            -- This works over SSH without X11 forwarding
            vim.g.clipboard = {
                name = "osc52",
                copy = { ["+"] = copy, ["*"] = copy },
                paste = { ["+"] = paste, ["*"] = paste },
            }
            
            -- Ensure clipboard option is set to use the custom provider
            vim.opt.clipboard = "unnamedplus"
            

            vim.o.laststatus = 2      -- ensures statusline always visible
            vim.o.statusline = "%f"   -- only show filename, no right section

            -- Print a message to confirm OSC52 is active
            if is_ssh_session() then
                vim.notify("OSC52 clipboard enabled for SSH session", vim.log.levels.INFO)
            end
        end
    end,
}


