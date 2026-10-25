local M = {}
function M.run(lines)
    local buf = vim.api.nvim_get_current_buf()
    if not require("config.buffer").regular(buf) then
        vim.notify("非普通文件或大文件：跳过格式化", vim.log.levels.WARN)
        return
    end
    local mode = vim.fn.mode()
    if not lines and (mode == "v" or mode == "V" or mode == "\22") then
        lines = { vim.fn.line("v"), vim.fn.line(".") }
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    end
    local range
    if lines then
        local first, last = math.min(unpack(lines)), math.max(unpack(lines))
        range = { start = { first, 0 }, ["end"] = { last, #vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] } }
    end
    local lsp_formatter = ({ cs = "roslyn", cmake = "neocmake" })[vim.bo[buf].filetype]
    if lsp_formatter then
        local clients = vim.lsp.get_clients({ bufnr = buf, name = lsp_formatter })
        local method = range and "textDocument/rangeFormatting" or "textDocument/formatting"
        if not clients[1] or not clients[1]:supports_method(method, buf) then
            vim.notify(lsp_formatter .. " 未就绪或不支持此范围格式化", vim.log.levels.WARN)
            return
        end
        local lsp_range = range and {
            start = { range.start[1], range.start[2] },
            ["end"] = { range["end"][1], range["end"][2] },
        } or nil
        vim.lsp.buf.format({ bufnr = buf, name = lsp_formatter, timeout_ms = 5000, range = lsp_range })
        return
    end
    local conform = require("conform")
    local available = conform.list_formatters(buf)
    if not vim.iter(available):any(function(f) return f.available end) then
        vim.notify("没有可用格式化器，请查看 :ConformInfo；不会自动切换工具。", vim.log.levels.WARN)
        return
    end
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000, lsp_format = "never", range = range })
end
return M
