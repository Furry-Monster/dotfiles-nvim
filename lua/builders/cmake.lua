local M = { filetypes = { 'c', 'cpp', 'cmake' }, tools = { 'cmake', 'ctest', 'ninja', 'make' } }
-- Plugin configuration is owned by cmake-tools; remember only overlays applied here.
local overlays = setmetatable({}, { __mode = 'k' })

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
    local cfg = cmake.get_config()
    local state = overlays[cfg]
    if not state then
        state = { env = {}, targets = {} }
        overlays[cfg] = state
    end
    -- Restore only keys previously overridden, retaining unrelated plugin settings.
    local env = vim.deepcopy(cfg.base_settings.env or {})
    for key, original in pairs(state.env) do
        env[key] = original ~= vim.NIL and original or nil
    end
    state.env = {}
    for key, value in pairs(ctx.build.env) do
        state.env[key] = env[key] == nil and vim.NIL or env[key]
        env[key] = value
    end
    cfg.base_settings.env = env
    return cmake
end

local function launch(ctx, debug)
    local cmake = enter(ctx)
    local function run()
        local target = cmake.get_launch_target()
        if target then
            local cfg = cmake.get_config()
            local state = overlays[cfg]
            if state.targets[target] then
                local settings = cfg.target_settings[target] or {}
                for _, key in ipairs({ 'working_dir', 'args', 'env' }) do
                    settings[key] = state.targets[target][key]
                end
                cfg.target_settings[target] = settings
                state.targets[target] = nil
            end
            if ctx.run_configured then
                local settings = cfg.target_settings[target] or {}
                state.targets[target] = {
                    working_dir = settings.working_dir,
                    args = vim.deepcopy(settings.args),
                    env = vim.deepcopy(settings.env),
                }
                cfg.target_settings[target] = vim.tbl_extend('force', settings, {
                    working_dir = ctx.run.cwd,
                    args = vim.deepcopy(ctx.run.args),
                    env = vim.deepcopy(ctx.run.env),
                })
            end
        end
        if debug then
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
        enter(ctx).generate({ fargs = ctx.configure.args })
    end,
    build = function(ctx)
        enter(ctx).build({ fargs = ctx.build.args })
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
