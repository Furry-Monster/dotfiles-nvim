return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = "Telescope",
        keys = {
            { "<C-p>", function() require("config.search").files() end, desc = "快速打开文件" },
            { "<leader>ff", function() require("config.search").files() end, desc = "工程文件" },
            { "<leader>fF", function() require("config.search").files(true) end, desc = "包含忽略文件（较慢）" },
            { "<leader>fg", function() require("config.search").grep() end, desc = "工程内容搜索" },
            { "<leader>fw", function() require("config.search").word() end, desc = "搜索光标单词" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffer 列表" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "帮助" },
            { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "快捷键" },
            { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "恢复上次搜索" },
            { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "文件符号" },
            { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "工程符号" },
            { "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "当前文件搜索" },
        },
        opts = {
            defaults = {
                sorting_strategy = "ascending",
                layout_config = { prompt_position = "top" },
                path_display = { "truncate" },
                mappings = { i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" } },
            },
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
        init = function()
            vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("WorkbenchDirectory", { clear = true }),
                callback = function()
                    local directory = vim.fn.argv(0)
                    if type(directory) == "string" and directory ~= "" and vim.fn.isdirectory(directory) == 1 then
                        require("nvim-tree.api").tree.open({ path = vim.fn.fnamemodify(directory, ":p") })
                    end
                end,
            })
        end,
        keys = {
            { "<leader>fe", function()
                require("nvim-tree.api").tree.toggle({ path = require("project.root").get() })
            end, desc = "工程文件树" },
            { "<leader>fE", "<cmd>NvimTreeFindFile<cr>", desc = "文件树定位" },
        },
        opts = {
            view = { width = 32 },
            -- All Git integrations live in one lifecycle-managed module.
            git = { enable = false },
            diagnostics = { enable = false },
            sync_root_with_cwd = false,
            respect_buf_cwd = false,
            update_focused_file = { enable = true, update_root = false },
            actions = { change_dir = { enable = false } },
            filters = {
                git_ignored = false,
                custom = { "^\\.git$", "^Library$", "^Temp$", "^obj$", "^target$", "^node_modules$" },
            },
            renderer = {
                group_empty = true,
                icons = { show = {
                    file = require("config.settings").icons,
                    folder = require("config.settings").icons,
                    folder_arrow = require("config.settings").icons,
                    git = false,
                } },
            },
        },
    },
}
