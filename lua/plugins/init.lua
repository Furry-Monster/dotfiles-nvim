return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        opts = {
            delay = 300,
            icons = { mappings = false },
            spec = {
                { '<leader>c', group = 'C/C++ / CMake' },
                { '<leader>d', group = 'Debug' },
                { '<leader>f', group = 'Find' },
                { '<leader>t', group = 'Terminal / scripts' },
                { '<leader>x', group = 'Diagnostics' },
            },
        },
    },
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
            require('workflow.lsp').setup()
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
                    require('conform').format({ async = true, lsp_format = 'fallback' })
                end,
                mode = { 'n', 'v' },
                desc = 'Format',
            },
        },
        opts = {
            formatters_by_ft = {
                c = { 'clang_format' },
                cpp = { 'clang_format' },
                glsl = { 'clang_format' },
                sh = { 'shfmt' },
                lua = { 'stylua' },
            },
            -- Explicit formatting preserves existing project conventions on save.
        },
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        cmd = 'Telescope',
        keys = {
            { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
            { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Search text' },
            { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
            { '<leader>fs', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Document symbols' },
            { '<leader>fS', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Workspace symbols' },
        },
        opts = { defaults = { file_ignore_patterns = { '^build/', '^out/', '^third_party/', '^vendor/' } } },
    },
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        lazy = false,
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter').setup({})
            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'c', 'cpp', 'cmake', 'sh', 'lua', 'json', 'glsl', 'ps1' },
                callback = function(event)
                    -- Vim syntax remains available if a parser is not installed.
                    pcall(vim.treesitter.start, event.buf)
                end,
            })
        end,
    },
    {
        'mfussenegger/nvim-dap',
        config = function()
            require('workflow.debug').setup()
        end,
    },
    {
        'Civitasv/cmake-tools.nvim',
        dependencies = { 'nvim-lua/plenary.nvim', 'mfussenegger/nvim-dap' },
        config = function()
            require('workflow.cmake').setup()
        end,
    },
}
