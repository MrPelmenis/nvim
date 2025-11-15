return {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" },
            { "williamboman/mason.nvim" },
            { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-nvim-lua" },

            -- Snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        },
        config = function()
            local lsp_zero = require("lsp-zero")

            lsp_zero.on_attach(function(client, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                lsp_zero.default_keymaps({ buffer = bufnr })

                -- Custom keymaps
                -- F2: Rename symbol everywhere
                vim.keymap.set("n", "<F2>", function()
                    vim.lsp.buf.rename()
                end, { buffer = bufnr, desc = "Rename symbol" })

                -- F12: Go to definition in a new tab
                vim.keymap.set("n", "<F12>", function()
                    local params = vim.lsp.util.make_position_params()
                    local result = vim.lsp.buf_request_sync(
                        bufnr,
                        "textDocument/definition",
                        params,
                        2000
                    )

                    if result and result[1] and result[1].result then
                        local def_result = result[1].result
                        -- Handle both Location and LocationLink types
                        if def_result.uri then
                            -- Single location
                            local uri = def_result.uri
                            local range = def_result.range or def_result.targetRange
                            
                            -- Create new tab
                            vim.cmd("tabnew")
                            
                            -- Open the file
                            local file_path = vim.uri_to_fname(uri)
                            vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                            
                            -- Jump to the location
                            if range then
                                local row = range.start.line + 1
                                local col = range.start.character
                                vim.api.nvim_win_set_cursor(0, { row, col })
                                vim.cmd("normal! zz") -- Center the line
                            end
                        elseif type(def_result) == "table" and #def_result > 0 then
                            -- Multiple locations, take the first one
                            local location = def_result[1]
                            if location.uri then
                                local uri = location.uri
                                local range = location.range or location.targetRange
                                
                                vim.cmd("tabnew")
                                local file_path = vim.uri_to_fname(uri)
                                vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                                
                                if range then
                                    local row = range.start.line + 1
                                    local col = range.start.character
                                    vim.api.nvim_win_set_cursor(0, { row, col })
                                    vim.cmd("normal! zz")
                                end
                            end
                        end
                    else
                        -- Fallback: use default definition and then move to new tab
                        local current_file = vim.api.nvim_buf_get_name(0)
                        local current_pos = vim.api.nvim_win_get_cursor(0)
                        
                        vim.lsp.buf.definition()
                        
                        -- Wait a bit for the jump to happen, then move to new tab
                        vim.defer_fn(function()
                            local new_file = vim.api.nvim_buf_get_name(0)
                            if new_file ~= current_file then
                                vim.cmd("tab split")
                            end
                        end, 100)
                    end
                end, { buffer = bufnr, desc = "Go to definition in new tab" })
            end)

            -- Configure Mason
            require("mason").setup({})
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "clangd",              -- C/C++
                    "ts_ls",  -- JavaScript/JSX/TypeScript
                    "html",            -- HTML
                    "cssls",             -- CSS
                    "intelephense",        -- PHP
                    "bashls",              -- Bash
                },
                handlers = {
                    lsp_zero.default_setup,
                },
            })

            -- Configure nvim-cmp for autocompletion
            local cmp = require("cmp")

            cmp.setup({
                sources = {
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "nvim_lua" },
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                }),
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
            })

            -- Configure LuaSnip
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
}

