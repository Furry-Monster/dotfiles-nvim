return {
    {
        "stevearc/overseer.nvim",
        cmd = {
            "OverseerRun", "OverseerToggle", "OverseerOpen", "OverseerShell", "OverseerTaskAction",
            "Build", "Task", "TaskRepeat", "TaskStop", "BuildDirectory", "CargoArgs",
            "CMakeConfigure", "CMakeBuild", "CMakeTarget", "CTest", "Cargo", "ShaderCheck",
        },
        keys = {
            { "<leader>bb", "<cmd>Build<cr>", desc = "构建工程" },
            { "<leader>bc", "<cmd>CMakeConfigure<cr>", desc = "CMake Configure" },
            { "<leader>bt", "<cmd>CMakeTarget<cr>", desc = "CMake Target" },
            { "<leader>bp", "<cmd>BuildDirectory<cr>", desc = "选择构建/编译数据库目录" },
            { "<leader>bo", "<cmd>OverseerToggle<cr>", desc = "任务面板" },
            { "<leader>br", "<cmd>TaskRepeat<cr>", desc = "重跑最近任务" },
            { "<leader>bs", "<cmd>TaskStop<cr>", desc = "停止工程任务" },
            { "<leader>bT", "<cmd>Task<cr>", desc = "项目自定义任务" },
            { "<leader>tt", function() require("config.tasks").test() end, desc = "运行测试" },
            { "<leader>tc", "<cmd>Cargo clippy<cr>", desc = "Cargo Clippy" },
        },
        opts = { dap = false, task_list = { direction = "bottom", min_height = 8, max_height = 16 } },
        config = function(_, opts)
            require("overseer").setup(opts)
            require("config.tasks").setup()
        end,
    },
}
