return {
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = "InsertEnter",
        opts = {
            enabled = function() return require("config.buffer").regular(0) end,
            keymap = { preset = "default", ["<CR>"] = { "accept", "fallback" } },
            completion = {
                list = { selection = { preselect = false, auto_insert = false } },
                documentation = { auto_show = true, auto_show_delay_ms = 250 },
                menu = { border = "rounded" },
                accept = { auto_brackets = { enabled = false } },
            },
            signature = { enabled = true, window = { border = "rounded" } },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
            fuzzy = { implementation = "lua" },
        },
    },
}
