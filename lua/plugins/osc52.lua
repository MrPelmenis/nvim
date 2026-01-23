return {
    "ojroques/nvim-osc52",
    config = function()
        require("osc52").setup({
            max_length = 0,
            silent = true,
            trim_whitespace = true,
        })

        -- 1. Check if the X11 Forwarding tunnel is actually active
        local has_display = vim.env.DISPLAY ~= nil

        if has_display then
            -- If we have an X11 tunnel, use the native system clipboard (xclip)
            -- This works with GNOME Terminal!
            vim.opt.clipboard = "unnamedplus"
            -- We don't need to do anything else; Neovim handles xclip automatically.
        else
            -- 2. Fallback: No X11 tunnel found, try to use OSC52
            -- (Note: This will only work if you switch away from GNOME Terminal later)
            local function copy(lines, _)
                require("osc52").copy(table.concat(lines, "\n"))
            end

            local function paste()
                return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
            end

            vim.g.clipboard = {
                name = "osc52",
                copy = { ["+"] = copy, ["*"] = copy },
                paste = { ["+"] = paste, ["*"] = paste },
            }
            vim.opt.clipboard = "unnamedplus"
        end
    end,
}
