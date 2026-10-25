local M = {}

function M.adapter()
    if vim.fn.executable('lldb-dap') == 1 then
        return 'lldb'
    end
    if vim.fn.executable('gdb') == 1 then
        return 'gdb'
    end
    return 'lldb'
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
    dap.adapters.cmake_cpp = function(callback)
        callback(dap.adapters[M.selected])
    end
    local function program()
        local path = vim.fn.input('Executable: ', vim.fn.getcwd() .. '/', 'file')
        return path ~= '' and path or dap.ABORT
    end
    local configs = {}
    for _, adapter in ipairs({ 'lldb', 'gdb' }) do
        table.insert(configs, {
            name = adapter .. ': launch executable',
            type = adapter,
            request = 'launch',
            program = program,
            cwd = '${workspaceFolder}',
            args = {},
            runInTerminal = true,
        })
        table.insert(configs, {
            name = adapter .. ': attach process',
            type = adapter,
            request = 'attach',
            pid = require('dap.utils').pick_process,
            program = program,
            cwd = '${workspaceFolder}',
        })
    end
    dap.configurations.c = vim.deepcopy(configs)
    dap.configurations.cpp = vim.deepcopy(configs)
    local function map(key, fn, desc)
        vim.keymap.set('n', key, fn, { desc = desc })
    end
    map('<F5>', dap.continue, 'Debug continue / choose launch')
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
        vim.notify('CMake debugger: ' .. opts.args)
    end, {
        nargs = 1,
        complete = function()
            return { 'lldb', 'gdb' }
        end,
    })
end

return M
