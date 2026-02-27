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
        "j-hui/fidget.nvim", -- Adds a useful status UI for LSP loading
        -- Tailwind CSS tools (LSP + inline color hints similar to VSCode)
        "luckasRanarison/tailwind-tools.nvim",
        -- Tailwind color squares in nvim-cmp completion menu
        "roobert/tailwindcss-colorizer-cmp.nvim",
    },

    config = function()
        -- Toggles (set these in your init.lua if you want)
        -- Always-visible errors on the right (end-of-line)
        if vim.g.lsp_inline_errors_enabled == nil then
            vim.g.lsp_inline_errors_enabled = true
        end
        -- Update diagnostics while typing (faster feedback)
        if vim.g.lsp_inline_errors_update_in_insert == nil then
            vim.g.lsp_inline_errors_update_in_insert = true
        end
        -- Optional: show a small floating diagnostic beside the error location on hold
        if vim.g.lsp_diagnostic_popup_enabled == nil then
            vim.g.lsp_diagnostic_popup_enabled = false
        end

        -- 1. Setup CMP (Autocompletion) first to prevent loading issues
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
                "clangd", -- C/C++
                "ts_ls",  -- JavaScript/TypeScript (Note: 'tsserver' was renamed to 'ts_ls')
                "eslint", -- Linter
                "lua_ls", -- Lua
                "pylsp",
                "tailwindcss", -- Tailwind CSS
            },
            handlers = {
                -- The default handler for all servers
                function(server_name)
                    require("lspconfig")[server_name].setup({
                        capabilities = capabilities
                    })
                end,

                -- Specific handler for C/C++ (clangd)
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
                                diagnostics = {
                                    globals = { "vim" }
                                }
                            }
                        }
                    })
                end,

                -- Tailwind CSS LSP: enable Tailwind class intelligence
                ["tailwindcss"] = function()
                    require("lspconfig").tailwindcss.setup({
                        capabilities = capabilities,
                        settings = {
                            tailwindCSS = {
                                experimental = {
                                    classRegex = {
                                        -- Typical React / JSX patterns
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

        -- 2. Configuration for UI Diagnostics (The "Red Squiggles")
        local ERROR_ONLY = { min = vim.diagnostic.severity.ERROR }
        vim.diagnostic.config({
            update_in_insert = vim.g.lsp_inline_errors_update_in_insert,
            severity_sort = true,
            virtual_text = vim.g.lsp_inline_errors_enabled and {
                severity = ERROR_ONLY,
                spacing = 2,
                source = "if_many",
            } or false,
            signs = { severity = ERROR_ONLY },
            underline = { severity = ERROR_ONLY },
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
                severity = ERROR_ONLY,
            },
        })

        -- Popup diagnostics beside the *actual* error column (right side).
        -- Triggered on CursorHold so you don't have to press anything.
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
            if #diags == 0 then
                return nil
            end

            -- Prefer diagnostic under cursor; else take the first on the line.
            for _, d in ipairs(diags) do
                local start_col = d.col or 0
                local end_col = d.end_col or start_col
                if cursor_col >= start_col and cursor_col <= end_col then
                    return d
                end
            end

            table.sort(diags, function(a, b)
                return (a.col or 0) < (b.col or 0)
            end)
            return diags[1]
        end

        local function open_diag_popup()
            if not vim.g.lsp_diagnostic_popup_enabled then
                close_diag_popup()
                return
            end

            local bufnr = vim.api.nvim_get_current_buf()
            local winid = vim.api.nvim_get_current_win()
            local cursor = vim.api.nvim_win_get_cursor(winid)
            local cursor_lnum = cursor[1] - 1
            local cursor_col = cursor[2]

            local diags = vim.diagnostic.get(bufnr, { lnum = cursor_lnum })
            local d = pick_diag_at_cursor(diags, cursor_col)
            if not d then
                close_diag_popup()
                return
            end

            -- Only show errors (warnings are intentionally hidden).
            if d.severity and d.severity > vim.diagnostic.severity.ERROR then
                close_diag_popup()
                return
            end

            local msg = d.message or ""
            if d.source and d.source ~= "" then
                msg = d.source .. ": " .. msg
            end
            local lines = vim.split(msg, "\n", { trimempty = true })
            if #lines == 0 then
                close_diag_popup()
                return
            end

            close_diag_popup()

            local float_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
            vim.bo[float_buf].modifiable = false
            vim.bo[float_buf].bufhidden = "wipe"

            local max_len = 1
            for _, l in ipairs(lines) do
                max_len = math.max(max_len, vim.fn.strdisplaywidth(l))
            end

            -- Try to anchor to the *diagnostic* column on screen.
            local diag_lnum = (d.lnum or cursor_lnum) + 1
            local diag_col = (d.col or cursor_col) + 1
            local spos = vim.fn.screenpos(winid, diag_lnum, diag_col)

            -- screenpos returns 0 when offscreen; fallback to cursor position.
            local screen_row = (spos.row and spos.row > 0) and spos.row or vim.fn.screenpos(winid, cursor[1], cursor_col + 1).row
            local screen_col = (spos.col and spos.col > 0) and spos.col or vim.fn.screenpos(winid, cursor[1], cursor_col + 1).col
            if not screen_row or screen_row == 0 or not screen_col or screen_col == 0 then
                close_diag_popup()
                return
            end

            local columns = vim.o.columns
            local desired_width = math.min(max_len, math.max(20, math.floor(columns * 0.35)))
            local height = math.min(#lines, 8)

            -- Place the popup to the right of the diagnostic if possible, else to the left.
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

            local float_win = vim.api.nvim_open_win(float_buf, false, win_opts)
            diag_popup.win = float_win
            diag_popup.buf = float_buf
        end

        if vim.g.lsp_diagnostic_popup_enabled then
            local diag_popup_group = vim.api.nvim_create_augroup("LspDiagnosticPopup", { clear = true })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinLeave" }, {
                group = diag_popup_group,
                callback = close_diag_popup,
            })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group = diag_popup_group,
                callback = open_diag_popup,
            })
        end

        -- 3. Keymaps (This runs only when an LSP attaches to a buffer)
        vim.api.nvim_create_autocmd('LspAttach', {
            desc = 'LSP actions',
            callback = function(event)
                local opts = { buffer = event.buf }

                vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
                vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
                vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
            end,
        })

        -- Tailwind Tools: VSCode-like Tailwind UX (inline color icons, etc.)
        tailwind_tools.setup({
            document_color = {
                enabled = true, -- show inline color squares
            },
            conceal = {
                enabled = false, -- set true if you want class name shortening
            },
            server = {
                -- we already configure `tailwindcss` above via lspconfig,
                -- so keep this minimal to avoid double-setup.
                override = false,
            },
        })

        -- 4. CMP Setup
        -- Tailwind colorizer: VSCode-style color squares in the completion popup.
        tailwind_colorizer.setup({
            color_square_width = 2,
        })

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            formatting = {
                -- Use tailwindcss-colorizer-cmp's formatter, but move the color square
                -- to the right-hand side of the label instead of the left.
                format = function(entry, vim_item)
                    local formatted = tailwind_colorizer.formatter(entry, vim_item)
                    if formatted.abbr and formatted.abbr:match("█") then
                        -- Move the color block(s) after the text
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
