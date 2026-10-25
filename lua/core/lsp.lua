local M = {}

function M.setup()
    vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        virtual_text = false,
        float = { border = 'rounded', source = true },
    })
    vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
    for _, name in ipairs(require('config.modules').languages) do
        local language = require('languages.' .. name)
        if language.setup_lsp then
            language.setup_lsp()
        end
    end
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('WorkflowLsp', { clear = true }),
        callback = function(event)
            local function map(key, fn, desc)
                vim.keymap.set('n', key, fn, { buffer = event.buf, desc = desc })
            end
            map('gd', vim.lsp.buf.definition, 'Definition')
            map('gD', vim.lsp.buf.declaration, 'Declaration')
            map('gr', vim.lsp.buf.references, 'References')
            map('gi', vim.lsp.buf.implementation, 'Implementation')
            map('K', vim.lsp.buf.hover, 'Hover')
            map('<leader>cr', vim.lsp.buf.rename, 'Rename symbol')
            map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
            map('<leader>ch', function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, 'Toggle inlay hints')
        end,
    })
end

return M
