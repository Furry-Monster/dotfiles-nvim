return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({})
            local function start(buf)
                if not require("config.buffer").regular(buf) then return end
                local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
                if not lang or not pcall(vim.treesitter.start, buf, lang) then return end
                vim.api.nvim_buf_call(buf, function()
                    vim.wo.foldmethod = "expr"
                    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                end)
            end
            local group = vim.api.nvim_create_augroup("WorkbenchTreesitter", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                callback = function(ev) start(ev.buf) end,
            })
            vim.api.nvim_create_user_command("ParsersInstall", function()
                require("nvim-treesitter").install({
                    "c", "cpp", "rust", "c_sharp", "lua", "luadoc", "vim", "vimdoc", "query",
                    "cmake", "bash", "json", "yaml", "toml", "xml",
                    "markdown", "markdown_inline", "glsl", "hlsl", "typescript", "tsx", "javascript",
                })
            end, { desc = "安装常用语法解析器（显式联网）" })
        end,
    },
}
