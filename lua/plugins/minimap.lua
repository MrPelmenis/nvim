return {
    "Isrothy/neominimap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    config = function()
        -- Toggle minimap
        vim.keymap.set('n', '<leader>mm', '<Cmd>NeominimapToggle<CR>', { desc = "Toggle Minimap" })
    end
}

