return {
    {
        'saghen/blink.cmp',
        event = 'InsertEnter',
        opts = {
            keymap = { preset = 'default' },
            completion = { documentation = { auto_show = true } },
            sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
            fuzzy = { implementation = 'lua' },
        },
    },
    {
        'neovim/nvim-lspconfig',
        config = function()
            require('core.lsp').setup()
        end,
        dependencies = { 'saghen/blink.cmp' },
    },
    {
        'stevearc/conform.nvim',
        cmd = { 'ConformInfo' },
        keys = {
            {
                '<leader>cf',
                function()
                    require('conform').format({ async = true })
                end,
                mode = { 'n', 'v' },
                desc = 'Format',
            },
        },
        opts = function()
            return require('core.format').options()
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        lazy = false,
        build = ':TSUpdate',
        config = function()
            require('core.syntax').setup()
        end,
    },
}
