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
                { '<leader>f', group = 'Find / replace' },
                { '<leader>g', group = 'Git' },
                { 'gs', group = 'Surround', mode = { 'n', 'x' } },
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
            {
                '<leader>ff',
                function()
                    require('core.search').open('find_files')
                end,
                desc = 'Find project files',
            },
            {
                '<leader>fg',
                function()
                    require('core.search').open('live_grep')
                end,
                desc = 'Search project text',
            },
            {
                '<leader>fw',
                function()
                    require('core.search').open('grep_string')
                end,
                desc = 'Search word in project',
            },
            {
                '<leader>fb',
                function()
                    require('core.search').open('buffers')
                end,
                desc = 'Project buffers',
            },
            {
                '<leader>fo',
                function()
                    require('core.search').open('oldfiles')
                end,
                desc = 'Recent project files',
            },
            {
                '<leader>fr',
                function()
                    require('core.search').resume()
                end,
                desc = 'Resume project search',
            },
            {
                '<leader>fs',
                function()
                    require('core.search').open('lsp_document_symbols')
                end,
                desc = 'Document symbols',
            },
            {
                '<leader>fS',
                function()
                    require('core.search').open('lsp_dynamic_workspace_symbols')
                end,
                desc = 'Workspace symbols',
            },
        },
        opts = function()
            return {
                defaults = {
                    file_ignore_patterns = require('config.search').ignore_patterns(),
                    cache_picker = { num_pickers = 10 },
                },
            }
        end,
    },
    {
        'MagicDuck/grug-far.nvim',
        cmd = 'GrugFar',
        keys = {
            {
                '<leader>fR',
                function()
                    require('core.search').replace()
                end,
                desc = 'Find and replace in project',
            },
            {
                '<leader>fW',
                function()
                    require('core.search').replace(true)
                end,
                desc = 'Replace word in project',
            },
        },
        opts = function()
            return {
                enabledEngines = { 'ripgrep' },
                engines = {
                    ripgrep = { extraArgs = table.concat(require('config.search').ripgrep_args(), ' ') },
                },
                history = { autoSave = { enabled = false } },
            }
        end,
    },
}
