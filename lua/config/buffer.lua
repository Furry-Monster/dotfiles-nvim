local M = {}

function M.large(buf)
    buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
    if vim.b[buf].large_file then
        return true
    end
    local limits = require("config.settings").large_file
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
    return (stat and stat.size > limits.bytes)
        or (vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_line_count(buf) > limits.lines)
        or false
end

function M.regular(buf)
    return vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_buf_is_loaded(buf)
        and vim.bo[buf].buftype == ""
        and not M.large(buf)
end

return M
