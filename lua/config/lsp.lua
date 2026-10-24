vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy"
    },
    filetypes = { "c", "cpp" },
    root_markers = {
        ".clangd",
        "compile_commands.json",
        "compile_flags.txt",
        ".git",
    }
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
    callback = function(event)
        local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, {
                buffer = event.buf,
                desc = desc
            })
        end

        map("gd", vim.lsp.buf.definition, "跳转到定义")
        map("gD", vim.lsp.buf.declaration, "跳转到声明")
        map("grr", vim.lsp.buf.references, "查找引用")
        map("grn", vim.lsp.buf.rename, "重命名符号")
        map("gra", vim.lsp.buf.code_action, "代码操作")
        map("K", vim.lsp.buf.hover, "查看符号信息")
        map("<leader>e", vim.diagnostic.open_float, "查看当前位置诊断")

        -- 使用内置补全，输入模式下通过 Ctrl-x Ctrl-o 触发。
        vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    end
})

vim.lsp.enable("clangd")
