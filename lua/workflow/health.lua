local M = {}
function M.check()
    vim.health.start('C/C++ graphics workflow')
    for _, exe in ipairs({ 'git', 'cmake', 'ctest', 'clangd', 'clang-format', 'rg' }) do
        if vim.fn.executable(exe) == 1 then
            vim.health.ok(exe .. ': ' .. vim.fn.exepath(exe))
        else
            vim.health.error('Missing ' .. exe)
        end
    end
    for _, exe in ipairs({
        'ninja',
        'make',
        'gcc',
        'clang',
        'lldb-dap',
        'gdb',
        'bash',
        'bash-language-server',
        'shellcheck',
        'shfmt',
        'neocmakelsp',
        'glsl_analyzer',
        'glslangValidator',
        'glslc',
        'spirv-val',
        'pwsh',
    }) do
        if vim.fn.executable(exe) == 1 then
            vim.health.ok(exe .. ': ' .. vim.fn.exepath(exe))
        else
            vim.health.warn('Optional tool missing: ' .. exe)
        end
    end
    vim.health.info(
        'GDB DAP needs GDB 14+ built with Python. Windows: use matching compiler/debugger toolchains.'
    )
    local bundle = vim.env.POWERSHELL_ES_BUNDLE
        or (vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services')
    if vim.fn.isdirectory(bundle) == 1 then
        vim.health.ok('PowerShell Editor Services: ' .. bundle)
    else
        vim.health.warn('PowerShell LSP missing; see README for POWERSHELL_ES_BUNDLE')
    end
end
return M
