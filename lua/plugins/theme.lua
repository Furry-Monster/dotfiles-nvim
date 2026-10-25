return {
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        lazy = false,
        priority = 1000,
        opts = {
            flavour = 'mocha',
            custom_highlights = function(colors)
                return {
                    WorkflowQuickfixNormal = { fg = colors.text, bg = colors.mantle },
                    WorkflowQuickfixEndOfBuffer = { fg = colors.mantle, bg = colors.mantle },
                    WorkflowQuickfixCursorLine = { bg = colors.surface0 },
                    WorkflowQuickfixSeparator = { fg = colors.surface2, bg = colors.mantle },
                    QuickFixFilename = { fg = colors.blue },
                    QuickFixFilenameInvalid = { fg = colors.overlay0 },
                    QuickFixLineNr = { fg = colors.peach },
                    QuickFixText = { fg = colors.text },
                    QuickFixTextInvalid = { fg = colors.overlay0 },
                    QuickFixHeaderHard = { fg = colors.lavender, bold = true },
                    QuickFixHeaderSoft = { fg = colors.overlay1 },
                }
            end,
        },
        config = function(_, opts)
            require('catppuccin').setup(opts)
            vim.cmd.colorscheme('catppuccin-mocha')
        end,
    },
}
