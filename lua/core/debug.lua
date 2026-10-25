local M = {}
local registry = require('core.registry')

function M.adapter()
    if vim.fn.executable('lldb-dap') == 1 then
        return 'lldb'
    end
    if vim.fn.executable('gdb') == 1 then
        return 'gdb'
    end
    return 'lldb'
end

function M.prepare(config, ctx)
    for _, name in ipairs(registry.names('languages')) do
        local language = registry.get('languages', name)
        if language.enrich_debug and vim.tbl_contains(language.filetypes or {}, ctx.filetype) then
            config = language.enrich_debug(config, ctx)
        end
    end
    return config
end

function M.configuration(ctx, adapter, overrides)
    local runtime = ctx.run
    local config = vim.tbl_extend('force', {
        name = 'Native ' .. adapter,
        type = adapter,
        request = 'launch',
        cwd = runtime.cwd,
        args = runtime.args,
        env = next(runtime.env) and runtime.env or nil,
        runInTerminal = true,
    }, overrides or {})
    return M.prepare(vim.deepcopy(config), ctx)
end

function M.configurations(ctx)
    if ctx.builder and ctx.builder.debug_configurations then
        return ctx.builder.debug_configurations(ctx)
    end
    local supported = false
    for _, name in ipairs(registry.names('languages')) do
        local language = registry.get('languages', name)
        if language.native_debug and vim.tbl_contains(language.filetypes or {}, ctx.filetype) then
            supported = true
        end
    end
    if not supported then
        return {}
    end
    local dap, configs = require('dap'), {}
    local function program()
        local path = vim.fn.input('Executable: ', ctx.root .. '/', 'file')
        return path ~= '' and path or dap.ABORT
    end
    for _, adapter in ipairs({ 'lldb', 'gdb' }) do
        table.insert(
            configs,
            M.configuration(ctx, adapter, { name = adapter .. ': launch executable', program = program })
        )
        table.insert(
            configs,
            M.configuration(ctx, adapter, {
                name = adapter .. ': attach process',
                request = 'attach',
                program = program,
                pid = require('dap.utils').pick_process,
            })
        )
    end
    return configs
end

function M.is_active()
    return require('dap').session() ~= nil
end

function M.continue()
    return require('dap').continue()
end

function M.setup()
    local dap = require('dap')
    dap.adapters.lldb = { type = 'executable', command = 'lldb-dap', name = 'lldb' }
    dap.adapters.gdb = {
        type = 'executable',
        command = 'gdb',
        args = { '--interpreter=dap', '--eval-command', 'set print pretty on' },
    }
    M.selected = M.adapter()
    -- CMake supplies the executable, cwd and env. Resolve the native adapter here,
    -- so builders never need to overwrite cmake-tools' global constants.
    dap.adapters.native = function(callback, config)
        local prepared = M.prepare(
            vim.tbl_extend('force', config, { type = M.selected }),
            require('core.context').resolve()
        )
        for key, value in pairs(prepared) do
            config[key] = value
        end
        local adapter = dap.adapters[config.type]
        if type(adapter) == 'function' then
            adapter(callback, config)
        else
            callback(adapter)
        end
    end
    for _, name in ipairs(registry.names('languages')) do
        local language = registry.get('languages', name)
        if language.setup_debug then
            language.setup_debug()
        end
    end
    dap.providers.configs['workflow.native'] = function(bufnr)
        local ctx = require('core.context').resolve(bufnr)
        if ctx.external.debug then
            return {}
        end
        return M.configurations(ctx)
    end
    local function map(key, fn, desc)
        vim.keymap.set('n', key, fn, { desc = desc })
    end
    map('<F10>', dap.step_over, 'Step over')
    map('<F11>', dap.step_into, 'Step into')
    map('<F12>', dap.step_out, 'Step out')
    map('<leader>db', dap.toggle_breakpoint, 'Breakpoint')
    map('<leader>dB', function()
        vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(value)
            if value and value ~= '' then
                dap.set_breakpoint(value)
            end
        end)
    end, 'Conditional breakpoint')
    map('<leader>dq', dap.terminate, 'Terminate debug session')
    map('<leader>dr', dap.repl.toggle, 'Debug REPL')
    map('<leader>dv', require('dap.ui.widgets').hover, 'Inspect variable')
    map('<leader>df', function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.frames)
    end, 'Stack frames')
    vim.api.nvim_create_user_command('DebugAdapter', function(opts)
        if not vim.tbl_contains({ 'lldb', 'gdb' }, opts.args) then
            return vim.notify('Use :DebugAdapter lldb or gdb', vim.log.levels.ERROR)
        end
        M.selected = opts.args
        vim.notify('Native debugger: ' .. opts.args)
    end, {
        nargs = 1,
        complete = function()
            return { 'lldb', 'gdb' }
        end,
    })
end

return M
