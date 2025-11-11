return {
    "ojroques/nvim-osc52",
    config = function()
        require("osc52").setup({
            max_length = 0, -- Maximum length of selection. 0 for no limit.
            silent = false, -- Disable message on successful copy.
            trim_whitespace = true, -- Trim whitespace before copy.
        })

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
    end,
}


