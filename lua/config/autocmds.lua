local group = vim.api.nvim_create_augroup("Workbench", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})
vim.api.nvim_create_autocmd("BufReadPre", {
    group = group,
    callback = function(ev)
        if require("config.buffer").large(ev.buf) then
            vim.b[ev.buf].large_file = true
            vim.b[ev.buf].minidiff_disable = true
        end
    end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(ev)
        if require("config.buffer").large(ev.buf) then
            vim.b[ev.buf].large_file = true
            vim.bo[ev.buf].syntax = "OFF"
            vim.bo[ev.buf].undolevels = 100
        end
        local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "help", "qf", "checkhealth", "lspinfo" },
    callback = function(ev)
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, desc = "关闭窗口" })
    end,
})
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
        if vim.bo[ev.buf].buftype == "" and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
            vim.t.workbench_root = require("project.root").get(ev.buf)
        end
    end,
})
vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function()
        vim.wo.number = false
        vim.wo.relativenumber = false
        vim.wo.signcolumn = "no"
    end,
})

vim.filetype.add({
    extension = {
        vert = "glsl", frag = "glsl", comp = "glsl", geom = "glsl", tesc = "glsl", tese = "glsl",
        glsl = "glsl", hlsl = "hlsl", hlsli = "hlsl", shader = "shaderlab", compute = "hlsl",
        ps1 = "ps1", psm1 = "ps1", nu = "nu",
    },
    filename = { justfile = "just", Justfile = "just", [".justfile"] = "just" },
})
