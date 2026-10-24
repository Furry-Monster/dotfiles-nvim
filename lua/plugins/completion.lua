return {
    {
        "saghen/blink.cmp",
        version = "1.*",
        lazy = false,
        opts = {
            keymap = {
                preset = "default",
            },
            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 300,
                },
                accept = {
                    auto_brackets = {
                        enabled = false,
                    },
                },
            },
            sources = {
                default = { "lsp", "path", "buffer" },
            },
            fuzzy = {
                implementation = "lua",
            },
        },
    },
}
