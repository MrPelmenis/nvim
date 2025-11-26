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
    "plugins.vscode",
    "plugins.treesitter",
    "plugins.telescope",
    "plugins.flash",
    "plugins.toggleterm",
    "plugins.nvim-tree",
    "plugins.osc52",
    "plugins.lsp",
    "plugins.rainbow-delimiters",
    "plugins.autoclose",
    "plugins.treesitter-context",
    "plugins.sessions",
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

-- Stay in visual mode after shifting
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true, silent = true })


-- Save shortcut (normal & insert mode)
vim.keymap.set({'n', 'i'}, '<C-s>', function() vim.cmd("write") end, { desc = "Save file" })

-- Select all (Ctrl+a)
vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true, desc = "Select entire file" })


-- ==========================
-- Colorscheme
-- ==========================
vim.cmd("colorscheme vscode")

