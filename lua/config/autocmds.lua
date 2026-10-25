local group = vim.api.nvim_create_augroup('WorkflowEditor', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    desc = 'Highlight copied text',
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { 'lua', 'sh', 'cmake', 'json', 'jsonc', 'yaml' },
    desc = 'Use two-space indentation for configuration and scripting files',
    callback = function(event)
        vim.bo[event.buf].shiftwidth = 2
        vim.bo[event.buf].tabstop = 2
    end,
})
