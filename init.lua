vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"
vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")

vim.g.mapleader = " "


vim.g.neovide_padding_top = 0
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_left = 0
vim.g.neovide_padding_right = 0

vim.o.showtabline = 2

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")

