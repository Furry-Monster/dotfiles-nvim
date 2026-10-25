local M = {}

function M.setup()
    require('cmake-tools').setup({
        cmake_use_preset = true,
        cmake_regenerate_on_save = false,
        cmake_generate_options = { '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON' },
        cmake_build_directory = 'build/${variant:buildType}',
        -- Copy works on Windows without symlink privileges. No .clangd rewrite.
        cmake_compile_commands_options = { action = 'copy', target = vim.uv.cwd },
        cmake_dap_configuration = {
            name = 'CMake target',
            type = 'cmake_cpp',
            request = 'launch',
            runInTerminal = true,
            initCommands = {},
        },
        cmake_executor = {
            name = 'quickfix',
            opts = {
                show = 'only_on_error',
                auto_close_when_success = false,
            },
        },
        cmake_runner = { name = 'terminal', opts = { focus = true, start_insert = true } },
        cmake_virtual_text_support = false,
    })
    local commands = {
        cp = { 'CMakeSelectConfigurePreset', 'Configure preset' },
        cP = { 'CMakeSelectBuildPreset', 'Build preset' },
        cg = { 'CMakeGenerate', 'CMake configure' },
        cb = { 'CMakeBuild', 'Build' },
        ct = { 'CMakeSelectBuildTarget', 'Build target' },
        cl = { 'CMakeSelectLaunchTarget', 'Launch target' },
        cR = { 'CMakeRun', 'Run target' },
        cd = { 'CMakeDebug', 'Debug target' },
        cT = { 'CMakeRunTest', 'CTest' },
        cx = { 'CMakeStopExecutor', 'Stop build' },
    }
    for key, value in pairs(commands) do
        vim.keymap.set('n', '<leader>' .. key, '<cmd>' .. value[1] .. '<cr>', { desc = value[2] })
    end
end

return M
