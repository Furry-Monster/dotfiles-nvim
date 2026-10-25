local M = { filetypes = { 'c', 'cpp', 'cmake' }, tools = { 'cmake', 'ctest', 'ninja', 'make' } }

function M.setup_plugin()
    require('cmake-tools').setup({
        cmake_use_preset = true,
        cmake_regenerate_on_save = false,
        cmake_generate_options = { '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON' },
        cmake_build_directory = 'build/${variant:buildType}',
        -- Copy works on Windows without symlink privileges. No .clangd rewrite.
        cmake_compile_commands_options = { action = 'copy', target = vim.uv.cwd },
        cmake_dap_configuration = {
            name = 'CMake target',
            type = 'native',
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
end

function M.detect(bufnr)
    local explicit = require('core.project').explicit_root(bufnr)
    if explicit and vim.fn.filereadable(explicit .. '/CMakeLists.txt') == 1 then
        return explicit
    end
    local preset = vim.fs.root(bufnr, { 'CMakePresets.json', 'CMakeUserPresets.json' })
    if preset then
        return preset
    end
    local repo = vim.fs.root(bufnr, { '.git' })
    if repo and vim.fn.filereadable(repo .. '/CMakeLists.txt') == 1 then
        return repo
    end
    return vim.fs.root(bufnr, { 'CMakeLists.txt' })
end

local function enter(ctx)
    if vim.fn.getcwd() ~= ctx.root then
        vim.cmd.cd(ctx.root)
    end
    local cmake = require('cmake-tools')
    local env = (ctx.project.build or {}).env
    if env then
        local cfg = cmake.get_config()
        cfg.base_settings.env = vim.tbl_extend('force', cfg.base_settings.env or {}, env)
    end
    return cmake
end

local function launch(ctx, debug)
    local cmake = enter(ctx)
    local function run()
        local target = cmake.get_launch_target()
        if (ctx.project.run or ctx.profile.runtime) and target then
            local runtime = require('core.project').runtime(ctx)
            local cfg = cmake.get_config()
            cfg.target_settings[target] = vim.tbl_extend('force', cfg.target_settings[target] or {}, {
                working_dir = runtime.cwd,
                args = runtime.args,
                env = runtime.env,
            })
        end
        if debug then
            local core = require('core.debug')
            require('cmake-tools.const').cmake_dap_configuration = core.prepare({
                name = 'CMake target',
                type = core.selected or core.adapter(),
                request = 'launch',
                runInTerminal = true,
                initCommands = {},
            }, ctx)
            cmake.debug({ fargs = {} })
        else
            cmake.run({ fargs = {} })
        end
    end
    if cmake.get_launch_target() then
        return run()
    end
    cmake.select_launch_target(false, function(result)
        if result:is_ok() then
            run()
        end
    end)
end

M.actions = {
    configure = function(ctx)
        enter(ctx).generate({ fargs = (ctx.project.configure or {}).args or {} })
    end,
    build = function(ctx)
        enter(ctx).build({ fargs = (ctx.project.build or {}).args or {} })
    end,
    run = function(ctx)
        launch(ctx, false)
    end,
    debug = function(ctx)
        launch(ctx, true)
    end,
    test = function(ctx)
        enter(ctx).run_test({ fargs = {} })
    end,
    stop = function(ctx)
        enter(ctx).stop_executor()
    end,
}
for action, command in pairs({
    configure_preset = 'CMakeSelectConfigurePreset',
    build_preset = 'CMakeSelectBuildPreset',
    build_target = 'CMakeSelectBuildTarget',
    launch_target = 'CMakeSelectLaunchTarget',
}) do
    M.actions[action] = function(ctx)
        enter(ctx)
        vim.cmd(command)
    end
end

return M
