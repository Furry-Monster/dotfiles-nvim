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
    local modules = require('config.modules')
    for _, name in ipairs(modules.languages) do
        vim.health.start('Language: ' .. name)
        tools(require('languages.' .. name).tools or {})
        local check = require('languages.' .. name).check_health
        if check then
            check()
        end
    end
    for _, name in ipairs(modules.builders) do
        local provider = require('builders.' .. name)
        if provider.tools then
            vim.health.start('Build provider: ' .. name)
            tools(provider.tools)
        end
    end
    vim.health.info('GDB DAP requires GDB 14+ with Python; Rust components must match the project toolchain.')
    vim.health.info('Workflow selection and external-action policy are independent of the source language.')
end
return M
