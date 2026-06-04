return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
        "luckasRanarison/tailwind-tools.nvim",
        "roobert/tailwindcss-colorizer-cmp.nvim",
    },

    config = function()
        -- Toggles (Global Settings)
        if vim.g.lsp_inline_errors_enabled == nil then
            vim.g.lsp_inline_errors_enabled = true
        end
        if vim.g.lsp_inline_errors_update_in_insert == nil then
            vim.g.lsp_inline_errors_update_in_insert = true
        end
        if vim.g.lsp_show_warnings == nil then
            vim.g.lsp_show_warnings = true
        end

        -- 1. Setup CMP & Capabilities
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local tailwind_tools = require("tailwind-tools")
        local tailwind_colorizer = require("tailwindcss-colorizer-cmp")

        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "clangd", "ts_ls", "eslint", "lua_ls", "pylsp", "tailwindcss", "rust_analyzer",
            },
            handlers = {
                -- Default handler for general servers
                function(server_name)
                    require("lspconfig")[server_name].setup({ capabilities = capabilities })
                end,

                -- Specific handler for C/C++
                ["clangd"] = function()
                    require("lspconfig").clangd.setup({
                        capabilities = capabilities,
                        cmd = {
                            "clangd",
                            "--background-index",
                            "--clang-tidy",
                            "--header-insertion=iwyu",
                            "--completion-style=detailed",
                            "--function-arg-placeholders",
                            "--fallback-style=llvm",
                        },
                        init_options = {
                            usePlaceholders = true,
                            completeUnimported = true,
                            clangdFileStatus = true,
                        },
                    })
                end,

                -- Specific handler for Lua
                ["lua_ls"] = function()
                    require("lspconfig").lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                diagnostics = { globals = { "vim" } }
                            }
                        }
                    })
                end,

                -- Specific handler for Rust (Casing Rules lint configuration)
                ["rust_analyzer"] = function()
                    require("lspconfig").rust_analyzer.setup({
                        capabilities = capabilities,
                        settings = {
                            ["rust-analyzer"] = {
                                checkOnSave = {
                                    command = "clippy", -- Runs Clippy lint checks on save to catch snake_case violations
                                },
                                diagnostics = {
                                    enable = true,
                                },
                            }
                        }
                    })
                end,

                -- Tailwind CSS LSP
                ["tailwindcss"] = function()
                    require("lspconfig").tailwindcss.setup({
                        capabilities = capabilities,
                        settings = {
                            tailwindCSS = {
                                experimental = {
                                    classRegex = {
                                        "className\\s*[:=]\\s*\"([^\"]*)\"",
                                        "className\\s*[:=]\\s*'([^']*)'",
                                        "className\\s*[:=]\\s*`([^`]*)`",
                                    },
                                },
                            },
                        },
                    })
                end,
            }
        })

        -- 2. Diagnostic UI Layout Setup
        local function update_diagnostic_ui()
            local severity_setting = { min = vim.diagnostic.severity.ERROR }
            if vim.g.lsp_show_warnings then
                severity_setting = { min = vim.diagnostic.severity.WARN }
            end

            vim.diagnostic.reset() -- Clean cache to prevent inline duplication overlays

            vim.diagnostic.config({
                update_in_insert = vim.g.lsp_inline_errors_update_in_insert,
                severity_sort = true,
                virtual_text = vim.g.lsp_inline_errors_enabled and {
                    severity = severity_setting,
                    spacing = 2,
                    source = "if_many",
                } or false,
                signs = { severity = severity_setting },
                underline = { severity = severity_setting },
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                    severity = severity_setting,
                },
            })
        end

        update_diagnostic_ui()

        -- Custom Screen-Anchored Diagnostic Side-Popup Window Functions
        local diag_popup = { win = nil, buf = nil }

        local function close_diag_popup()
            if diag_popup.win and vim.api.nvim_win_is_valid(diag_popup.win) then
                pcall(vim.api.nvim_win_close, diag_popup.win, true)
            end
            if diag_popup.buf and vim.api.nvim_buf_is_valid(diag_popup.buf) then
                pcall(vim.api.nvim_buf_delete, diag_popup.buf, { force = true })
            end
            diag_popup.win = nil
            diag_popup.buf = nil
        end

        local function pick_diag_at_cursor(diags, cursor_col)
            if #diags == 0 then return nil end
            for _, d in ipairs(diags) do
                local start_col = d.col or 0
                local end_col = d.end_col or start_col
                if cursor_col >= start_col and cursor_col <= end_col then
                    return d
                end
            end
            table.sort(diags, function(a, b) return (a.col or 0) < (b.col or 0) end)
            return diags[1]
        end

        local function open_diag_popup()
            close_diag_popup()

            local bufnr = vim.api.nvim_get_current_buf()
            local winid = vim.api.nvim_get_current_win()
            local cursor = vim.api.nvim_win_get_cursor(winid)
            local cursor_lnum = cursor[1] - 1
            local cursor_col = cursor[2]

            local diags = vim.diagnostic.get(bufnr, { lnum = cursor_lnum })
            local d = pick_diag_at_cursor(diags, cursor_col)
            if not d then return end

            if not vim.g.lsp_show_warnings and d.severity and d.severity > vim.diagnostic.severity.ERROR then
                return
            end

            local msg = d.message or ""
            if d.source and d.source ~= "" then
                msg = d.source .. ": " .. msg
            end
            local lines = vim.split(msg, "\n", { trimempty = true })
            if #lines == 0 then return end

            local float_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
            vim.bo[float_buf].modifiable = false
            vim.bo[float_buf].bufhidden = "wipe"

            local max_len = 1
            for _, l in ipairs(lines) do
                max_len = math.max(max_len, vim.fn.strdisplaywidth(l))
            end

            local diag_lnum = (d.lnum or cursor_lnum) + 1
            local diag_col = (d.col or cursor_col) + 1
            local spos = vim.fn.screenpos(winid, diag_lnum, diag_col)

            local screen_row = (spos.row and spos.row > 0) and spos.row or
            vim.fn.screenpos(winid, cursor[1], cursor_col + 1).row
            local screen_col = (spos.col and spos.col > 0) and spos.col or
            vim.fn.screenpos(winid, cursor[1], cursor_col + 1).col
            if not screen_row or screen_row == 0 or not screen_col or screen_col == 0 then
                return
            end

            local columns = vim.o.columns
            local desired_width = math.min(max_len, math.max(20, math.floor(columns * 0.35)))
            local height = math.min(#lines, 8)

            local right_col = screen_col + 1
            local left_col = screen_col - desired_width - 2
            local place_right = (right_col + desired_width) < columns

            local win_opts = {
                relative = "editor",
                row = screen_row - 1,
                col = place_right and right_col - 1 or math.max(0, left_col - 1),
                width = desired_width,
                height = height,
                style = "minimal",
                border = "rounded",
                focusable = false,
                noautocmd = true,
                zindex = 60,
            }

            diag_popup.win = vim.api.nvim_open_win(float_buf, false, win_opts)
            diag_popup.buf = float_buf
        end

        -- Autocommands to dismiss side-popup window
        local diag_popup_group = vim.api.nvim_create_augroup("LspDiagnosticPopup", { clear = true })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinLeave" }, {
            group = diag_popup_group,
            callback = close_diag_popup,
        })

        -- 3. Global Diagnostics Keymaps
        -- Toggle Visibility between (Errors Only) & (Warnings + Errors)
        vim.keymap.set('n', '<leader>k', function()
            vim.g.lsp_show_warnings = not vim.g.lsp_show_warnings
            update_diagnostic_ui()
            close_diag_popup()
            if vim.g.lsp_show_warnings then
                print("LSP Diagnostics: Showing Errors & Warnings")
            else
                print("LSP Diagnostics: Errors Only")
            end
        end, { desc = "Toggle LSP Warning Visibility" })

        -- Yank/Copy Error text under cursor directly to system clipboard
        vim.keymap.set('n', '<leader>cy', function()
            local bufnr = vim.api.nvim_get_current_buf()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local diags = vim.diagnostic.get(bufnr, { lnum = cursor[1] - 1 })
            if #diags == 0 then return end

            local target = diags[1]
            for _, d in ipairs(diags) do
                if cursor[2] >= (d.col or 0) and cursor[2] <= (d.end_col or d.col or 0) then
                    target = d
                    break
                end
            end
            local msg = target.message
            if target.source then msg = "[" .. target.source .. "] " .. msg end
            vim.fn.setreg('+', msg)
            print("Copied diagnostic to clipboard!")
        end, { desc = "Copy current diagnostic error text" })

        -- Buffer Local Actions (Applies when an LSP is hooked)
        vim.api.nvim_create_autocmd('LspAttach', {
            desc = 'LSP actions',
            callback = function(event)
                local opts = { buffer = event.buf }

                vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
                vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)

                -- 'K' triggers the custom side-anchored popup window layout manually
                vim.keymap.set('n', 'K', function()
                    if diag_popup.win and vim.api.nvim_win_is_valid(diag_popup.win) then
                        close_diag_popup()
                    else
                        open_diag_popup()
                    end
                end, opts)
            end,
        })

        -- Tailwind Tools Configuration
        tailwind_tools.setup({
            document_color = { enabled = true },
            conceal = { enabled = false },
            server = { override = false },
        })

        -- 4. CMP Auto-completion Engine Setup
        tailwind_colorizer.setup({ color_square_width = 2 })

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(),
                ['<C-n>'] = cmp.mapping.select_next_item(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            formatting = {
                format = function(entry, vim_item)
                    local formatted = tailwind_colorizer.formatter(entry, vim_item)
                    if formatted.abbr and formatted.abbr:match("█") then
                        local square = formatted.abbr:match("█+%s*") or ""
                        local label = formatted.abbr:gsub("█+%s*", "")
                        formatted.abbr = label .. " " .. square
                    end
                    return formatted
                end,
            },
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
            }, {
                { name = 'buffer' },
            })
        })
    end
}
