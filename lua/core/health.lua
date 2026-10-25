local M = {}
function M.check()
    local seen = {}
    local function tools(names)
        for _, exe in ipairs(names) do
            if not seen[exe] then
                seen[exe] = true
                if vim.fn.executable(exe) == 1 then
                    vim.health.ok(exe .. ': ' .. vim.fn.exepath(exe))
                else
                    vim.health.warn('Tool not found: ' .. exe .. ' (installation is user-managed)')
                end
            end
        end
    end
    vim.health.start('Shared editor services')
    tools({ 'git', 'rg', 'lldb-dap', 'gdb' })
    local registry = require('core.registry')
    local function load(kind, name)
        local path = kind .. '.' .. name
        local ok, provider = pcall(registry.get, kind, name)
        if not ok then
            vim.health.error('Cannot load ' .. path .. ': ' .. tostring(provider))
            return
        end
        vim.health.ok('Module loaded: ' .. path)
        return provider
    end
    for _, name in ipairs(registry.names('languages')) do
        vim.health.start('Language: ' .. name)
        local language = load('languages', name)
        if language then
            tools(language.tools or {})
            if language.check_health then
                language.check_health()
            end
        end
    end
    for _, name in ipairs(registry.names('builders')) do
        vim.health.start('Build provider: ' .. name)
        local provider = load('builders', name)
        if provider then
            tools(provider.tools or {})
        end
    end
    for _, name in ipairs(registry.names('workflows')) do
        vim.health.start('Workflow: ' .. name)
        load('workflows', name)
    end
    vim.health.info('GDB DAP requires GDB 14+ with Python; Rust components must match the project toolchain.')
    vim.health.info('Workflow selection and external-action policy are independent of the source language.')
end
return M
