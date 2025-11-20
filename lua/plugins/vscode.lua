return {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,  -- This ensures it loads first
    config = function()
        -- Optional configuration
        require("vscode").setup({
            -- Enable transparent background
            transparent = false,
            -- Enable italic comment
            italic_comments = true,
            -- Disable nvim-tree background color
            disable_nvimtree_bg = true,
        })
    end
}
