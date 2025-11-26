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
      -- Enable default keybinds
      lsp_zero.default_keymaps({ buffer = bufnr })
    end)

    -- Configure Mason
	require("mason").setup({})
	require("mason-lspconfig").setup({
  	ensure_installed = { "clangd" },
          handlers = {
           function(server)
           local opts = {}
           if server == "clangd" then
            opts.cmd = {
              "clangd",
              "-DBUILD_DISCOVERY_SERVER",
              "-DBUILD_ABC",
              "-DBUILD_AUTHORIZATION_SERVER"
            }
           end
         -- fallback to default setup for all servers
         lsp_zero.default_setup(server, opts)
         end,
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
