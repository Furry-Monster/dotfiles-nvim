return {
    {
        'mfussenegger/nvim-dap',
        config = function()
            require('core.debug').setup()
        end,
    },
    {
        'Civitasv/cmake-tools.nvim',
        dependencies = { 'nvim-lua/plenary.nvim', 'mfussenegger/nvim-dap' },
        config = function()
            require('builders.cmake').setup_plugin()
        end,
    },
}
