-- Uses installed plugins without installing or updating them.
-- Run: nvim -i NONE --headless '+lua dofile("tests/plugins.lua")'
assert(#require('lazy').plugins() > 0, 'Plugin declarations were not loaded')
for _, command in ipairs({
    'Cargo',
    'CargoStop',
    'ProjectInfo',
    'ProjectAction',
    'WorkflowHealth',
    'CMakeGenerate',
    'DebugAdapter',
}) do
    assert(vim.fn.exists(':' .. command) == 2, 'Missing command: ' .. command)
end
assert(vim.fn.maparg('<F5>', 'n') ~= '', 'Missing project debug binding')
local dap = require('dap')
local context = require('core.context')
local rust = require('toolchains.rust')
local resolve, info = context.resolve, rust.info
local ctx = resolve()
ctx.filetype = 'rust'
context.resolve = function()
    return ctx
end
rust.info = function()
    return 'fixture-host', nil
end
local core = require('core.debug')
local original_selection = core.selected
core.selected = 'gdb'
local config = {
    name = 'CMake target',
    type = 'native',
    request = 'launch',
    program = '/tmp/fixture',
    initCommands = {},
}
local adapter
dap.adapters.native(function(value)
    adapter = value
end, config)
assert(config.type == 'rust_gdb' and config.rustRoot == ctx.root, 'Native Rust enrichment failed')
assert(adapter.command == 'gdb', 'Wrong native adapter')
assert(
    require('cmake-tools.const').cmake_dap_configuration.type == 'native',
    'CMake global DAP config was overwritten'
)
core.selected = original_selection
context.resolve, rust.info = resolve, info
-- Re-registering entry points must not accumulate lifecycle handlers.
require('config.workflow').setup()
assert(#vim.api.nvim_get_autocmds({ group = 'WorkflowTasks' }) == 1)
local before = vim.api.nvim_exec2('messages', { output = true }).output
assert(before == '', 'Unexpected startup messages: ' .. before)
print('PASS: installed plugin startup, existing commands/bindings, native adapter and repeatable setup')
vim.cmd('qa!')
