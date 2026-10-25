return {
    {
        'stevearc/quicker.nvim',
        ft = 'qf',
        opts = {
            edit = { enabled = false, autosave = false },
            opts = {
                cursorline = true,
                number = false,
                relativenumber = false,
                signcolumn = 'auto',
                winfixheight = true,
                wrap = false,
                statusline = ' %q %=%l/%L ',
                winhighlight = table.concat({
                    'Normal:WorkflowQuickfixNormal',
                    'NormalNC:WorkflowQuickfixNormal',
                    'EndOfBuffer:WorkflowQuickfixEndOfBuffer',
                    'CursorLine:WorkflowQuickfixCursorLine',
                    'QuickFixLine:WorkflowQuickfixCursorLine',
                    'WinSeparator:WorkflowQuickfixSeparator',
                    'Delimiter:WorkflowQuickfixSeparator',
                }, ','),
            },
            keys = {
                {
                    '>',
                    function()
                        require('quicker').expand({ before = 2, after = 2 })
                    end,
                    desc = 'Expand code context',
                },
                {
                    '<',
                    function()
                        require('quicker').collapse()
                    end,
                    desc = 'Collapse code context',
                },
                { 'q', '<cmd>close<cr>', desc = 'Close quickfix' },
            },
        },
    },
}
