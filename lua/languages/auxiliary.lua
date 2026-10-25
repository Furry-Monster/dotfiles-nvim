local M = {
    tools = {
        'bash-language-server',
        'shellcheck',
        'shfmt',
        'neocmakelsp',
        'pwsh',
    },
    formatters = { sh = { 'shfmt' } },
    treesitter = { 'cmake', 'sh', 'json', 'ps1' },
}

function M.setup()
    vim.filetype.add({ extension = { ps1 = 'ps1', psm1 = 'ps1', psd1 = 'ps1' } })
end

function M.setup_lsp()
    vim.lsp.config('neocmake', { root_markers = { 'CMakePresets.json', '.git', 'CMakeLists.txt' } })
    for server, exe in pairs({
        bashls = 'bash-language-server',
        neocmake = 'neocmakelsp',
    }) do
        if vim.fn.executable(exe) == 1 then
            vim.lsp.enable(server)
        end
    end
    local bundle = vim.env.POWERSHELL_ES_BUNDLE
    if
        bundle
        and vim.fn.executable('pwsh') == 1
        and vim.fn.filereadable(bundle .. '/PowerShellEditorServices/Start-EditorServices.ps1') == 1
    then
        vim.lsp.config('powershell_es', { bundle_path = bundle })
        vim.lsp.enable('powershell_es')
    end
end

function M.check_health()
    local bundle = vim.env.POWERSHELL_ES_BUNDLE
    if
        bundle
        and vim.fn.filereadable(bundle .. '/PowerShellEditorServices/Start-EditorServices.ps1') == 1
    then
        vim.health.ok('PowerShell Editor Services: ' .. bundle)
    else
        vim.health.warn('PowerShell Editor Services bundle not found; see README')
    end
end

return M
