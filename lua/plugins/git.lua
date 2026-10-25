return {
    {
        'lewis6991/gitsigns.nvim',
        event = function(plugin)
            -- Keep manual installation available without firing missing-plugin errors on file open.
            return vim.fn.isdirectory(plugin.dir .. '/lua') == 1 and { 'BufReadPre', 'BufNewFile' } or {}
        end,
        opts = {
            current_line_blame = false,
            on_attach = function(bufnr)
                require('core.git').on_attach(bufnr)
            end,
        },
    },
}
