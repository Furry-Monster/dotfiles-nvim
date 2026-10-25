return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        version = "*",
        opts = { style = "night", styles = { floats = "normal", sidebars = "normal" } },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            vim.cmd.colorscheme("tokyonight")
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
        enabled = require("config.settings").icons,
        opts = {},
    },
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function()
            local features = require("config.features")
            return {
                options = {
                    theme = "tokyonight",
                    icons_enabled = require("config.settings").icons,
                    globalstatus = true,
                    component_separators = "│",
                    section_separators = "",
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = {
                        {
                            function()
                                return vim.b.minidiff_summary_string or ""
                            end,
                            cond = function() return features.git end,
                        },
                        "diagnostics",
                    },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = {
                        {
                            function()
                                if not features.ai then return "AI:OFF" end
                                return require("config.ai").allowed() and "AI:ON" or "AI:BLOCK"
                            end,
                            on_click = function() require("config.ai").toggle() end,
                            color = function()
                                return { fg = features.ai and "#e0af68" or "#737aa2" }
                            end,
                        },
                        {
                            function() return features.git and "Git:ON" or "Git:OFF" end,
                            on_click = function() features.set("git", not features.git) end,
                        },
                        {
                            function() return "Quiet" end,
                            on_click = features.off,
                            color = { fg = "#9ece6a" },
                        },
                        "filetype",
                    },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
                extensions = { "nvim-tree", "quickfix", "overseer", "nvim-dap-ui" },
            }
        end,
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            delay = 350,
            icons = { mappings = require("config.settings").icons },
            spec = {
                { "<leader>a", group = "AI" },
                { "<leader>b", group = "构建 / Buffer" },
                { "<leader>c", group = "代码" },
                { "<leader>d", group = "调试" },
                { "<leader>f", group = "搜索" },
                { "<leader>g", group = "Git" },
                { "<leader>p", group = "项目 / 配置" },
                { "<leader>t", group = "测试" },
                { "<leader>u", group = "开关 / UI" },
                { "<leader>x", group = "诊断 / Quickfix" },
            },
        },
    },
}
