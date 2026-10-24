return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        cmd = "Telescope",
        keys = {
            {
                "<leader>ff",
                "<cmd>Telescope find_files<CR>",
                desc = "查找文件",
            },
            {
                "<leader>fg",
                "<cmd>Telescope live_grep<CR>",
                desc = "搜索项目文本",
            },
            {
                "<leader>fb",
                "<cmd>Telescope buffers<CR>",
                desc = "查找 buffer",
            },
            {
                "<leader>fh",
                "<cmd>Telescope help_tags<CR>",
                desc = "搜索帮助",
            },
        },
        opts = {},
        config = function(_, opts)
            require("telescope").setup(opts)
        end,
    },
}
