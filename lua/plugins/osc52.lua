return {
    "ojroques/nvim-osc52",
    config = function()
        local osc52 = require("osc52")
        
        osc52.setup({
            max_length = 0,
            silent = true,
            trim_whitespace = true,
        })

        -- Force OSC 52 for everything. Ignore X11/DISPLAY.
        local function copy(lines, _)
            osc52.copy(table.concat(lines, "\n"))
        end

        local function paste()
            -- Note: OSC52 'paste' is technically limited by terminal security.
            -- This fallback uses the internal register.
            return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
        end

        vim.g.clipboard = {
            name = "osc52",
            copy = { ["+"] = copy, ["*"] = copy },
            paste = { ["+"] = paste, ["*"] = paste },
        }
        
        vim.opt.clipboard = "unnamedplus"

        -- Optional: specific keymap if you want to copy manually
        vim.keymap.set('n', '<leader>y', osc52.copy_operator, {desc = "Copy to system clipboard via OSC52"})
        vim.keymap.set('v', '<leader>y', osc52.copy_visual, {desc = "Copy to system clipboard via OSC52"})
    end,
}
