-- Run: nvim --headless '+lua dofile("tests/integration.lua")' +qa
-- Creates a disposable project in the OS temporary directory.
local function run()
    local config_dir = vim.fn.stdpath('config')
    local original_cwd = vim.fn.getcwd()
    local root = vim.fn.tempname() .. ' cpp workflow'
    vim.fn.mkdir(root, 'p')
    vim.fn.writefile(
        vim.fn.readfile(config_dir .. '/examples/CMakePresets.json'),
        root .. '/CMakePresets.json'
    )
    vim.fn.writefile({
        'cmake_minimum_required(VERSION 3.21)',
        'project(workflow_probe LANGUAGES C CXX)',
        'include(CTest)',
        'add_executable(probe main.cpp)',
        'target_compile_definitions(probe PRIVATE WORKFLOW_PROBE=42)',
        'add_test(NAME probe COMMAND probe)',
    }, root .. '/CMakeLists.txt')
    vim.fn.writefile({
        '#ifndef WORKFLOW_PROBE',
        '#error missing compilation database',
        '#endif',
        'int main() {',
        '    volatile int value = WORKFLOW_PROBE;',
        '    return value == 42 ? 0 : 1;',
        '}',
    }, root .. '/main.cpp')
    local function exec(argv)
        local result = vim.system(argv, { cwd = root, text = true, env = { CCACHE_DISABLE = '1' } }):wait()
        assert(result.code == 0, table.concat(argv, ' ') .. '\n' .. result.stdout .. result.stderr)
    end
    for _, preset in ipairs({ 'gcc-debug', 'gcc-release', 'clang-debug', 'clang-release', 'gcc-make-debug' }) do
        exec({ 'cmake', '--preset', preset })
        exec({ 'cmake', '--build', '--preset', preset, '--parallel', '2' })
        exec({ 'ctest', '--preset', preset })
        print('PASS configure/build/CTest: ' .. preset)
    end

    vim.cmd.cd(root)
    local cmake = require('cmake-tools')
    local cfg = cmake.get_config()
    cfg.configure_preset = 'gcc-debug'
    cfg.build_preset = 'gcc-debug'
    cfg.build_target = { 'probe' }
    cfg.launch_target = 'probe'
    local function await_action(action)
        local done, result = false, nil
        action(function(value)
            result, done = value, true
        end)
        assert(
            vim.wait(30000, function()
                return done
            end, 20),
            'CMake plugin timed out'
        )
        assert(result:is_ok(), vim.inspect(result))
    end
    await_action(function(cb)
        cmake.generate({ fargs = {} }, cb)
    end)
    await_action(function(cb)
        cmake.build({ fargs = {} }, cb)
    end)
    assert(vim.fn.filereadable(root .. '/compile_commands.json') == 1, 'database was not copied')
    assert(cmake.get_launch_target_path():find('probe', 1, true), 'CMake executable target discovery failed')
    print('PASS CMake plugin configure/build/compilation database/target discovery')

    vim.cmd.edit(root .. '/main.cpp')
    local source_buf = vim.api.nvim_get_current_buf()
    assert(
        vim.wait(15000, function()
            return #vim.lsp.get_clients({ bufnr = 0, name = 'clangd' }) > 0
        end, 50),
        'clangd did not attach'
    )
    local client = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })[1]
    local hover
    assert(
        vim.wait(15000, function()
            local response = client:request_sync('textDocument/hover', {
                textDocument = { uri = vim.uri_from_fname(root .. '/main.cpp') },
                position = { line = 4, character = 30 },
            }, 1500, 0)
            hover = response and response.result
            return hover ~= nil
        end, 100),
        'clangd hover failed'
    )
    assert(vim.inspect(hover):find('42', 1, true), 'clangd did not resolve the CMake macro')
    print('PASS clangd attach and CMake macro resolution')

    local before = table.concat(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false), '\n')
    local format_error
    require('conform').format({ async = false, timeout_ms = 3000 }, function(err)
        format_error = err
    end)
    assert(not format_error, vim.inspect(format_error))
    assert(before ~= table.concat(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false), '\n'))
    assert(vim.bo.filetype == 'cpp')
    print('PASS C++ formatter invocation')
    local dap = require('dap')
    for _, adapter in ipairs({ 'lldb', 'gdb' }) do
        vim.cmd('DebugAdapter ' .. adapter)
        local stopped = false
        dap.listeners.after.event_stopped.workflow_test = function()
            stopped = true
        end
        dap.run({
            type = 'native',
            request = 'launch',
            name = 'workflow test ' .. adapter,
            program = root .. '/build/gcc-debug/probe',
            cwd = root,
            stopOnEntry = true,
            stopAtBeginningOfMainSubprogram = true,
            initCommands = { 'settings set target.disable-aslr false' },
        })
        assert(
            vim.wait(15000, function()
                local session = dap.session()
                return stopped and session and session.current_frame and session.current_frame.scopes
            end, 30),
            adapter .. ' did not stop and populate stack/scopes'
        )
        local done = false
        dap.terminate(nil, nil, function()
            done = true
        end)
        assert(
            vim.wait(10000, function()
                return done
            end, 30),
            adapter .. ' did not terminate'
        )
        dap.listeners.after.event_stopped.workflow_test = nil
        print('PASS DAP launch/stop/terminate: ' .. adapter)
    end
    vim.cmd('DebugAdapter gdb')
    assert(require('core.debug').selected == 'gdb')
    vim.cmd('DebugAdapter lldb')
    assert(require('core.debug').selected == 'lldb')
    vim.cmd.cd(original_cwd)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):find(root, 1, true) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
    vim.fn.delete(root, 'rf')
    print('ALL INTEGRATION CHECKS PASSED')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd('cquit 1')
end
