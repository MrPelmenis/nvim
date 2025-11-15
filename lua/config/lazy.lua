-- ==========================
-- Basic Editor Settings
-- ==========================
vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.g.mapleader = " "


-- Search settings: case-insensitive by default
vim.opt.ignorecase = true
vim.opt.smartcase = true  -- If search contains uppercase, then case-sensitive

-- Terminal keycode setup for Windows/WSL
-- Enable keycode timeout to help recognize special keys
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 50

-- ==========================
-- Bootstrap Lazy.nvim
-- ==========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================
-- Plugins
-- ==========================
-- Load all plugins from individual files
local plugins = {}
local plugin_files = {
    "plugins.tokyonight",
    "plugins.treesitter",
    "plugins.telescope",
    "plugins.flash",
    "plugins.toggleterm",
    "plugins.nvim-tree",
    "plugins.osc52",
    "plugins.minimap",
}

for _, plugin_file in ipairs(plugin_files) do
    local plugin = require(plugin_file)
    if type(plugin) == "table" then
        table.insert(plugins, plugin)
    elseif type(plugin) == "function" then
        table.insert(plugins, plugin())
    end
end

require("lazy").setup(plugins)

-- ==========================
-- Keymaps
-- ==========================
-- Search
vim.keymap.set('n', '<C-f>', '/', { desc = "Search in current file" })
vim.keymap.set('i', '<C-f>', '<Esc>/', { desc = "Search in current file" })
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = "Clear search highlight" })

-- Clipboard
vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set({'n', 'v'}, '<C-v>', '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set('i', '<C-v>', '<C-r>+', { desc = "Paste from system clipboard in insert mode" })

-- Save shortcut (normal & insert mode)
vim.keymap.set({'n', 'i'}, '<C-s>', function() vim.cmd("write") end, { desc = "Save file" })

-- Select all (Ctrl+a)
vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true, desc = "Select entire file" })


-- ==========================
-- File Type Associations
-- ==========================
-- React/JSX files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "*.jsx", "*.tsx" },
    callback = function()
        vim.bo.filetype = "typescriptreact"
    end,
})

-- Tailwind CSS
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "*.css" },
    callback = function()
        -- Check if it's likely a Tailwind file (you can adjust this logic)
        local content = vim.fn.readfile(vim.fn.expand("%"), "", 10)
        for _, line in ipairs(content) do
            if line:match("@tailwind") or line:match("@apply") then
                vim.bo.filetype = "css"
                break
            end
        end
    end,
})

-- Makefile detection
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "Makefile", "makefile", "*.mk", "*.make" },
    callback = function()
        vim.bo.filetype = "make"
    end,
})

-- Nginx/OpenResty config files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "*.conf", "nginx.conf", "*.nginx" },
    callback = function()
        -- Try to detect nginx configs
        local filename = vim.fn.expand("%:t")
        if filename:match("nginx") or vim.fn.getcwd():match("nginx") then
            vim.bo.filetype = "nginx"
        end
    end,
})

-- Apache config files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "httpd.conf", ".htaccess", "apache*.conf" },
    callback = function()
        vim.bo.filetype = "apache"
    end,
})

-- C/C++ header files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "*.h", "*.hpp", "*.hxx" },
    callback = function()
        local ext = vim.fn.expand("%:e")
        if ext == "hpp" or ext == "hxx" then
            vim.bo.filetype = "cpp"
        else
            -- Try to detect C vs C++ based on content
            local content = vim.fn.readfile(vim.fn.expand("%"), "", 5)
            for _, line in ipairs(content) do
                if line:match("namespace") or line:match("class ") or line:match("template") then
                    vim.bo.filetype = "cpp"
                    return
                end
            end
            vim.bo.filetype = "c"
        end
    end,
})

vim.api.nvim_create_user_command('W', function()
    local ok, _ = pcall(vim.cmd, 'write')
    if not ok then
        vim.cmd('silent! write !sudo tee % >/dev/null')
    end
end, {})

-- Language-specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "typescript", "typescriptreact", "jsx", "tsx" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.softtabstop = 4
        vim.bo.shiftwidth = 4
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "html", "css", "scss" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.softtabstop = 4
        vim.bo.shiftwidth = 4
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "php" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.softtabstop = 4
        vim.bo.shiftwidth = 4
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.softtabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.cindent = true
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "make" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.softtabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.expandtab = false  -- Makefiles require tabs
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "nginx", "apache" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.softtabstop = 4
        vim.bo.shiftwidth = 4
    end,
})

-- ==========================
-- Colorscheme
-- ==========================
vim.cmd("colorscheme tokyonight-night")

