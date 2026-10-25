local M = {}

function M.options()
    local formatters, options = {}, {}
    for _, name in ipairs(require('config.modules').languages) do
        formatters = vim.tbl_extend('force', formatters, require('languages.' .. name).formatters or {})
        options = vim.tbl_extend('force', options, require('languages.' .. name).formatter_options or {})
    end
    return {
        default_format_opts = { lsp_format = 'fallback' },
        formatters_by_ft = formatters,
        formatters = options,
    }
end

return M
