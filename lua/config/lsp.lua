local M = {}

-- Public RPC factory: select project arguments before starting the process.
function M.command(base, extend)
    return function(dispatchers, config)
        local cmd = vim.deepcopy(base)
        local root = config.root_dir or vim.fn.getcwd()
        local project = require("project.settings").get(root)
        if extend then extend(cmd, project, require("project.settings").base(root)) end
        return vim.lsp.rpc.start(cmd, dispatchers, {
            cwd = root,
            env = vim.tbl_extend("force", config.cmd_env or {}, project.env or {}),
        })
    end
end

function M.root(markers)
    return function(buf, on_dir)
        if not require("config.buffer").regular(buf) then return end
        local root = vim.fs.root(buf, markers)
        on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)))
    end
end

function M.setup()
    vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
    local group = vim.api.nvim_create_augroup("WorkbenchLsp", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(ev)
            if require("config.buffer").large(ev.buf) then
                vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
                return
            end
            local function map(lhs, rhs, desc)
                vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
            end
            map("gd", vim.lsp.buf.definition, "定义")
            map("gD", vim.lsp.buf.declaration, "声明")
            map("grr", vim.lsp.buf.references, "引用")
            map("gri", vim.lsp.buf.implementation, "实现")
            map("grt", vim.lsp.buf.type_definition, "类型定义")
            map("K", vim.lsp.buf.hover, "文档")
            map("<F12>", vim.lsp.buf.definition, "定义")
            map("<F2>", vim.lsp.buf.rename, "重命名")
            map("<leader>cr", vim.lsp.buf.rename, "重命名")
            map("<leader>ca", vim.lsp.buf.code_action, "代码操作")
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client.name == "clangd" then
                map("<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", "切换头文件 / 源文件")
            end
            vim.keymap.set("x", "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "选区代码操作" })
        end,
    })
    require("languages.cpp").setup()
    require("languages.rust").setup()
    require("languages.auxiliary").setup()
    vim.api.nvim_create_user_command("LspRestart", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local restart = {}
        for _, client in ipairs(clients) do
            if client.name ~= "copilot" then
                table.insert(restart, {
                    config = vim.deepcopy(client.config),
                    buffers = vim.tbl_keys(client.attached_buffers),
                })
                client:stop()
            end
        end
        vim.defer_fn(function()
            for _, item in ipairs(restart) do
                for _, buf in ipairs(item.buffers) do
                    if require("config.buffer").regular(buf) then
                        vim.lsp.start(item.config, { bufnr = buf })
                    end
                end
            end
        end, 500)
    end, { desc = "重启当前文件的语言服务（同根工程共享实例）" })
end

return M
