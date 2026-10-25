local M = {}

function M.options()
    local formatters, options = {}, {}
    require('core.registry').each('languages', function(language)
        formatters = vim.tbl_extend('force', formatters, language.formatters or {})
        options = vim.tbl_extend('force', options, language.formatter_options or {})
    end)
    return {
        default_format_opts = { lsp_format = 'fallback' },
        formatters_by_ft = formatters,
        formatters = options,
    }
end

return M
