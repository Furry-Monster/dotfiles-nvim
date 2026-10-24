return {
    {
        "nvim-tree/nvim-tree.lua",
        lazy = false,
        keys = {
            {
                "<leader>ee",
                "<cmd>NvimTreeToggle<CR>",
                desc = "切换文件树",
            },
            {
                "<leader>ef",
                "<cmd>NvimTreeFindFile<CR>",
                desc = "在文件树定位当前文件",
            },
        },
        opts = {
            view = {
                width = 34,
            },
            renderer = {
                group_empty = true,
                icons = {
                    show = {
                        file = false,
                        folder = false,
                        folder_arrow = false,
                        git = false,
                    },
                },
            },
            filters = {
                dotfiles = false,
                git_ignored = true,
            },

            -- 文件树不自动改变编辑器工作目录。
            sync_root_with_cwd = false,
            update_focused_file = {
                enable = true,
                update_root = false,
            },
            actions = {
                change_dir = {
                    enable = false,
                },
            },
        },
    },
}
