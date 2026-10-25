local M = {}

function M.setup()
    require('nvim-treesitter').setup({})
    require('core.folds').setup()
    local patterns = {}
    require('core.registry').each('languages', function(language)
        vim.list_extend(patterns, language.treesitter or {})
    end)
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('WorkflowSyntax', { clear = true }),
        pattern = patterns,
        callback = function(event)
            pcall(vim.treesitter.start, event.buf)
        end,
    })
end

return M
