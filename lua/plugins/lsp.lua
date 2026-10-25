return {
    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
        opts = {
            PATH = "append",
            registries = {
                "github:mason-org/mason-registry",
                -- roslyn only: the non-nightly VS Code server distribution.
                "github:Crashdummyy/mason-registry",
            },
            ui = { border = "rounded" },
        },
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
        config = function() require("config.lsp").setup() end,
    },
    {
        "seblyng/roslyn.nvim",
        ft = "cs",
        dependencies = { "neovim/nvim-lspconfig" },
        init = function()
            -- Upstream plugin enables its daemon immediately when sourced.
            -- Delay that entry point until our command and SDK checks are ready.
            vim.g.loaded_roslyn_plugin = true
        end,
        config = function()
            require("languages.csharp").setup()
        end,
    },
}
