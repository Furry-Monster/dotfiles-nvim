return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        opts = {
            delay = 300,
            icons = { mappings = false },
            spec = {
                { '<leader>c', group = 'Code / build' },
                { '<leader>d', group = 'Debug' },
                { '<leader>f', group = 'Find' },
                { '<leader>t', group = 'Terminal / scripts' },
                { '<leader>x', group = 'Diagnostics' },
            },
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
}
