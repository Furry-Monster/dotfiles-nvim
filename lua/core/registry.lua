local M = {}
local modules = require('config.modules')
local check = require('core.validate')

---@class LanguageModule
---@field filetypes? string[]
---@field tools? string[]
---@field treesitter? string[] Filetypes to highlight, not parser names.
---@field formatters? table
---@field formatter_options? table
---@field native_debug? boolean
---@field setup? fun() Filetypes and other editor integration, independent of LSP.
---@field setup_lsp? fun()
---@field setup_debug? fun()
---@field enrich_debug? fun(config: table, ctx: ProjectContext): table
---@field check_health? fun()

---@class BuildProvider
---@field actions table<string, fun(ctx: ProjectContext, args?: string[]): any>
---@field filetypes? string[]
---@field tools? string[]
---@field detect? fun(source: integer|string): string?
---@field setup? fun()
---@field parse? fun(stdout: string, stderr: string, root: string): table, table?
---@field debug_configurations? fun(ctx: ProjectContext): table[]

---@class WorkflowProfile
---@field detect? fun(source: integer|string): string?
---@field default_builder? string|false
---@field external? table<string, boolean>
---@field external_handler? string
---@field runtime? table

local checked = setmetatable({}, { __mode = 'k' })

function M.names(kind)
    local names = assert(modules[kind], 'Unknown module kind: ' .. tostring(kind))
    check.strings(names, 'config.modules.' .. kind)
    local seen = {}
    for _, name in ipairs(names) do
        assert(not seen[name], 'Duplicate module: ' .. kind .. '.' .. name)
        seen[name] = true
    end
    return names
end

function M.get(kind, name)
    assert(vim.tbl_contains(M.names(kind), name), 'Unregistered module: ' .. kind .. '.' .. tostring(name))
    local path = kind .. '.' .. name
    local provider = require(path)
    if checked[provider] == path then
        return provider
    end
    check.object(provider, path)
    for _, field in ipairs({ 'filetypes', 'tools', 'treesitter' }) do
        if provider[field] ~= nil then
            check.strings(provider[field], path .. '.' .. field)
        end
    end
    for _, field in ipairs({
        'setup',
        'setup_lsp',
        'setup_debug',
        'check_health',
        'detect',
        'parse',
        'enrich_debug',
        'debug_configurations',
    }) do
        if provider[field] ~= nil then
            check.expect(provider[field], 'function', path .. '.' .. field)
        end
    end
    for _, field in ipairs({ 'formatters', 'formatter_options', 'runtime' }) do
        if provider[field] ~= nil then
            check.object(provider[field], path .. '.' .. field)
        end
    end
    if kind == 'builders' then
        check.map(provider.actions, 'function', path .. '.actions')
    elseif kind == 'workflows' then
        if provider.runtime ~= nil then
            check.command_options(provider.runtime, path .. '.runtime')
        end
        if provider.external then
            check.map(provider.external, 'boolean', path .. '.external')
        end
        if provider.default_builder ~= nil and provider.default_builder ~= false then
            assert(
                vim.tbl_contains(M.names('builders'), provider.default_builder),
                path .. '.default_builder is not registered'
            )
        end
        if provider.external_handler ~= nil then
            check.expect(provider.external_handler, 'string', path .. '.external_handler')
        end
    end
    if provider.native_debug ~= nil then
        check.expect(provider.native_debug, 'boolean', path .. '.native_debug')
    end
    checked[provider] = path
    return provider
end

function M.each(kind, callback)
    for _, name in ipairs(M.names(kind)) do
        callback(M.get(kind, name), name)
    end
end

return M
