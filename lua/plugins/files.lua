return {
    {
        'nvim-tree/nvim-tree.lua',
        lazy = false,
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        init = function()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
        end,
        keys = {
            { '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file sidebar' },
        },
        opts = {
            view = { side = 'left', width = 32 },
            update_focused_file = { enable = true },
            renderer = { icons = { show = { file = true, folder = true, git = true } } },
            on_attach = function(bufnr)
                local api = require('nvim-tree.api')
                api.map.on_attach.default(bufnr)
                local function map(key, action, desc)
                    vim.keymap.set('n', key, action, { buffer = bufnr, silent = true, desc = desc })
                end
                map('h', api.node.navigate.parent_close, 'Close directory / parent')
                map('l', api.node.open.edit, 'Open file / directory')
                for arrow, key in pairs({ Left = 'h', Down = 'j', Up = 'k', Right = 'l' }) do
                    vim.keymap.set(
                        'n',
                        '<' .. arrow .. '>',
                        key,
                        { buffer = bufnr, remap = true, silent = true }
                    )
                end
                -- Replace tree-local Ctrl-k (info) with the shared window navigation.
                require('config.navigation').setup(bufnr)
            end,
        },
    },
}
