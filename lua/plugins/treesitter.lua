return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup(
                    "user_treesitter",
                    { clear = true }
                ),
                pattern = {
                    "c",
                    "cpp",
                    "lua",
                    "rust",
                    "cmake",
                },
                callback = function(event)
                    vim.treesitter.start(event.buf)
                end,
            })
        end
    }
}
