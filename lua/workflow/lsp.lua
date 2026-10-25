local M = {}

function M.setup()
    local bin = vim.fn.stdpath('data') .. '/mason/bin'
    if vim.fn.isdirectory(bin) == 1 then
        local sep = vim.fn.has('win32') == 1 and ';' or ':'
        -- Prefer system compilers/clangd, then fall back to installed tools.
        vim.env.PATH = vim.env.PATH .. sep .. bin
    end
    vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        virtual_text = false,
        float = { border = 'rounded', source = true },
    })
    vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
    local cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--completion-style=detailed',
        '--header-insertion=iwyu',
    }
    -- Limit driver discovery to explicitly named, installed compilers.
    local drivers = {}
    for _, name in ipairs({ 'gcc', 'g++', 'clang', 'clang++' }) do
        local path = vim.fn.exepath(name)
        if path ~= '' then
            table.insert(drivers, path)
        end
    end
    if #drivers > 0 then
        table.insert(cmd, '--query-driver=' .. table.concat(drivers, ','))
    end
    vim.lsp.config('clangd', {
        cmd = cmd,
        root_markers = {
            'CMakePresets.json',
            'CMakeUserPresets.json',
            '.clangd',
            'compile_commands.json',
            '.git',
            'CMakeLists.txt',
        },
    })
    vim.lsp.config('neocmake', {
        root_markers = { 'CMakePresets.json', '.git', 'CMakeLists.txt' },
    })
    for server, exe in pairs({
        clangd = 'clangd',
        bashls = 'bash-language-server',
        neocmake = 'neocmakelsp',
        glsl_analyzer = 'glsl_analyzer',
    }) do
        if vim.fn.executable(exe) == 1 then
            vim.lsp.enable(server)
        end
    end
    local bundle = vim.env.POWERSHELL_ES_BUNDLE
        or (vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services')
    if vim.fn.executable('pwsh') == 1 and vim.fn.isdirectory(bundle) == 1 then
        vim.lsp.config('powershell_es', { bundle_path = bundle })
        vim.lsp.enable('powershell_es')
    end
    vim.api.nvim_create_autocmd('LspAttach', {
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
            if vim.lsp.get_client_by_id(event.data.client_id).name == 'clangd' then
                map('<leader>cs', '<cmd>LspClangdSwitchSourceHeader<cr>', 'Switch source/header')
            end
        end,
    })
end

return M
