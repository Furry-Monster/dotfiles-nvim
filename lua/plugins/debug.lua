return {
    {
        "mfussenegger/nvim-dap",
        dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
        keys = {
            { "<F5>", function() require("dap").continue() end, desc = "调试启动 / 继续" },
            { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "断点" },
            { "<F10>", function() require("dap").step_over() end, desc = "单步跳过" },
            { "<F11>", function() require("dap").step_into() end, desc = "单步进入" },
            { "<S-F11>", function() require("dap").step_out() end, desc = "单步跳出" },
            { "<S-F5>", function() require("dap").terminate() end, desc = "停止调试" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "断点" },
            { "<leader>dc", function() require("config.debug").conditional() end, desc = "条件断点" },
            { "<leader>dl", function() require("config.debug").logpoint() end, desc = "日志断点" },
            { "<leader>du", function() require("dapui").toggle() end, desc = "调试面板" },
            { "<leader>de", function() require("dapui").eval() end, mode = { "n", "x" }, desc = "求值 / 监视" },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "调试控制台" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "停止调试" },
            { "<leader>da", function() require("config.debug").arguments() end, desc = "程序参数（JSON argv）" },
        },
        config = function() require("config.debug").setup() end,
    },
}
