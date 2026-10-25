local M = {}

function M.setup()
    require('nvim-treesitter').setup({})
    local patterns = {}
    for _, name in ipairs(require('config.modules').languages) do
        vim.list_extend(patterns, require('languages.' .. name).treesitter or {})
    end
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('WorkflowSyntax', { clear = true }),
        pattern = patterns,
        callback = function(event)
            pcall(vim.treesitter.start, event.buf)
        end,
    })
end

return M
