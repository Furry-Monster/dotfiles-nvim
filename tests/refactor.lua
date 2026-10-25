-- Run without plugins or external test frameworks: nvim --clean -l tests/refactor.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local count = 0
local function equal(actual, expected)
    assert(vim.deep_equal(actual, expected), vim.inspect(actual) .. ' ~= ' .. vim.inspect(expected))
end
local function fails(fn, fragment)
    local ok, err = pcall(fn)
    assert(
        not ok and tostring(err):find(fragment, 1, true),
        'Expected error containing ' .. fragment .. ': ' .. tostring(err)
    )
end
local function test(name, fn)
    fn()
    count = count + 1
    print('PASS: ' .. name)
end
local base = vim.fn.tempname() .. ' nvim refactor'
vim.fn.mkdir(base, 'p')
local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile(type(lines) == 'table' and lines or { lines }, path)
end
local function project(name, data)
    local root = base .. '/' .. name
    vim.fn.mkdir(root, 'p')
    write(root .. '/.nvim/project.json', vim.json.encode(next(data) == nil and vim.empty_dict() or data))
    return root
end
local context = require('core.context')
local registry = require('core.registry')
local modules = require('config.modules')
local notifications = {}
vim.notify = function(message)
    notifications[#notifications + 1] = tostring(message)
end

test('registered providers satisfy their contracts', function()
    for _, kind in ipairs({ 'languages', 'builders', 'workflows' }) do
        registry.each(kind, function() end)
    end
    table.insert(modules.builders, 'invalid_test')
    package.loaded['builders.invalid_test'] = { actions = { build = true } }
    fails(function()
        registry.get('builders', 'invalid_test')
    end, 'builders.invalid_test.actions.build')
    package.loaded['builders.invalid_test'] = nil
    table.remove(modules.builders)
    table.insert(modules.languages, modules.languages[1])
    fails(function()
        registry.names('languages')
    end, 'Duplicate module')
    table.remove(modules.languages)
end)

test('project validation reports field paths and handles invalid JSON', function()
    for _, fixture in ipairs({
        { { run = { args = 'wrong' } }, '.run.args' },
        { { build = { env = { BAD = false } } }, '.build.env.BAD' },
        { { tasks = { build = { argv = {} } } }, '.tasks.build.argv' },
        { { external = { debug = 'yes' } }, '.external.debug' },
        { { builder = 'missing' }, '.builder' },
        { { languages = { rust = false } }, '.languages.rust' },
    }) do
        local root = project('invalid', fixture[1])
        fails(function()
            context.resolve(root)
        end, fixture[2])
    end
    local root = base .. '/invalid'
    for _, raw in ipairs({ '[]', 'null', 'false', '{bad' }) do
        write(root .. '/.nvim/project.json', raw)
        fails(function()
            require('core.project').load(root)
        end, root .. '/.nvim/project.json')
    end
end)

test('workflow defaults reach Cargo and debug through one context', function()
    table.insert(modules.workflows, 'fixture')
    package.loaded['workflows.fixture'] = {
        default_builder = 'cargo',
        runtime = { cwd = 'assets', args = { 'default' }, env = { PROFILE = 'yes', SHARED = 'profile' } },
        external = { test = true },
    }
    local root = project('defaults', {
        workflow = 'fixture',
        build = { env = { BUILD = 'yes', SHARED = 'build' } },
        run = { args = { 'override' }, env = { SHARED = 'run' } },
        external = { test = false },
    })
    write(root .. '/Cargo.toml', { '[package]', 'name="defaults"', 'version="0.1.0"' })
    local ctx = context.resolve(root)
    equal(ctx.run, {
        cwd = root .. '/assets',
        args = { 'override' },
        env = { PROFILE = 'yes', BUILD = 'yes', SHARED = 'run' },
    })
    equal(ctx.external.test, false)
    equal(require('projects.cargo').options(ctx).run, ctx.run)
    local cfg = require('core.debug').configuration(ctx, 'lldb')
    equal({ cfg.cwd, cfg.args, cfg.env }, { ctx.run.cwd, ctx.run.args, ctx.run.env })
    local before = vim.deepcopy(ctx)
    require('projects.cargo').args(require('projects.cargo').options(ctx), 'build', { '--offline' }, true)
    equal(ctx, before)
    package.loaded['workflows.fixture'] = nil
    table.remove(modules.workflows)
end)

test('builder false, builder override, Unity detection, and filetype selection', function()
    local root = project('disabled', { builder = false })
    write(root .. '/Cargo.toml', '[workspace]')
    equal(context.resolve(root).builder_name, nil)
    equal(context.resolve(root, { builder = 'cargo' }).builder_name, 'cargo')
    equal(context.resolve(root).root, root)
    local unity = base .. '/unity'
    write(unity .. '/ProjectSettings/ProjectVersion.txt', 'm_EditorVersion: 6000')
    vim.fn.mkdir(unity .. '/Assets', 'p')
    write(unity .. '/CMakeLists.txt', 'project(unity)')
    local ctx = context.resolve(unity)
    equal({ ctx.workflow, ctx.builder_name, ctx.external.debug }, { 'unity', nil, true })
    local mixed = project('mixed', {})
    write(mixed .. '/CMakeLists.txt', 'project(mixed)')
    write(mixed .. '/Cargo.toml', '[workspace]')
    equal(context.resolve(mixed, { filetype = 'rust' }).builder_name, 'cargo')
    equal(context.resolve(mixed, { filetype = 'cpp' }).builder_name, 'cmake')
end)

test('action precedence and errors remain explicit', function()
    local root = project('dispatch', { builder = 'commands', tasks = { build = { argv = { 'unused' } } } })
    local ctx = context.resolve(root)
    local commands = require('builders.commands')
    local original = commands.run_task
    local called = 0
    commands.run_task = function()
        called = called + 1
        return 'custom'
    end
    ctx.external.build = true
    require('core.actions').dispatch(ctx, 'build')
    equal(called, 0)
    ctx.external.build = false
    equal(require('core.actions').dispatch(ctx, 'build'), 'custom')
    equal(called, 1)
    commands.run_task = original
    local debug = require('core.debug')
    local active, continue = debug.is_active, debug.continue
    debug.is_active = function()
        return true
    end
    debug.continue = function()
        return 'continued'
    end
    ctx.builder = { actions = {
        debug = function()
            return 'provider'
        end,
    } }
    equal(require('core.actions').dispatch(ctx, 'debug'), 'continued')
    debug.is_active = function()
        return false
    end
    equal(require('core.actions').dispatch(ctx, 'debug'), 'provider')
    debug.is_active, debug.continue = active, continue
    ctx.tasks = {}
    ctx.builder = {
        actions = {
            build = function()
                error('fixture failure')
            end,
        },
    }
    fails(function()
        require('core.actions').dispatch(ctx, 'build')
    end, 'fixture failure')
    local result, err = require('core.actions').execute('build', { builder = 'not_registered' })
    equal(result, nil)
    assert(tostring(err):find('Unregistered module', 1, true))
end)

test('Cargo command generation uses snapshot without re-reading project.json', function()
    local root =
        project('cargo args', { builder = 'cargo', run = { cwd = 'assets', args = { 'hello world' } } })
    local ctx = context.resolve(root)
    write(root .. '/.nvim/project.json', '{invalid after resolution')
    local tasks = require('core.tasks')
    local original, captured = tasks.terminal
    tasks.terminal = function(opts)
        captured = opts
    end
    require('builders.cargo').command(ctx, 'run', { '--offline' })
    tasks.terminal = original
    equal(
        captured.argv,
        { 'cargo', 'run', '--manifest-path', root .. '/Cargo.toml', '--offline', '--', 'hello world' }
    )
    equal(captured.cwd, root .. '/assets')
    equal(captured.root, root)
end)

test('CMake overlays are reversible and do not cross projects', function()
    local original, original_cwd = package.loaded['cmake-tools'], vim.fn.getcwd()
    local configs = {}
    local function cfg()
        local root = vim.fn.getcwd()
        configs[root] = configs[root]
            or {
                base_settings = { env = { BASE = 'original', KEEP = 'yes' } },
                target_settings = {
                    app = {
                        working_dir = 'plugin-dir',
                        args = { 'plugin' },
                        env = { PLUGIN = 'yes' },
                        custom = true,
                    },
                },
            }
        return configs[root]
    end
    package.loaded['cmake-tools'] = {
        get_config = cfg,
        get_launch_target = function()
            return 'app'
        end,
        build = function() end,
        run = function() end,
        debug = function() end,
    }
    local cmake = require('builders.cmake')
    local a = project('cmake a', {
        builder = 'cmake',
        build = { env = { BASE = 'override', ADDED = 'yes' } },
        run = { cwd = 'assets' },
    })
    local b = project('cmake b', { builder = 'cmake' })
    cmake.actions.run(context.resolve(a))
    equal(cfg().base_settings.env.BASE, 'override')
    equal(cfg().target_settings.app.working_dir, a .. '/assets')
    cmake.actions.run(context.resolve(b))
    equal(cfg().base_settings.env, { BASE = 'original', KEEP = 'yes' })
    equal(cfg().target_settings.app.working_dir, 'plugin-dir')
    write(a .. '/.nvim/project.json', '{"builder":"cmake"}')
    cmake.actions.run(context.resolve(a))
    equal(cfg().base_settings.env, { BASE = 'original', KEEP = 'yes' })
    equal(
        cfg().target_settings.app,
        { working_dir = 'plugin-dir', args = { 'plugin' }, env = { PLUGIN = 'yes' }, custom = true }
    )
    cmake.actions.run(context.resolve(a))
    equal(cfg().base_settings.env, { BASE = 'original', KEEP = 'yes' })
    package.loaded['cmake-tools'] = original
    vim.cmd.cd(original_cwd)
end)

test('filetype setup is independent of LSP', function()
    registry.each('languages', function(language)
        if language.setup then
            language.setup()
        end
    end)
    equal(vim.filetype.match({ filename = 'shader.rgen' }), 'glsl')
    equal(vim.filetype.match({ filename = 'shader.slang' }), 'shaderslang')
    equal(vim.filetype.match({ filename = 'script.ps1' }), 'ps1')
end)

test('process and terminal task ownership, stopping, and cleanup', function()
    local tasks = require('core.tasks')
    tasks.setup()
    tasks.setup()
    equal(#vim.api.nvim_get_autocmds({ group = 'WorkflowTasks' }), 1)
    local done
    tasks.start({
        argv = { 'sh', '-c', 'printf test' },
        cwd = base,
        root = 'process',
        parse = function(stdout)
            equal(stdout, 'test')
            return {}
        end,
    }, function(success)
        done = success
    end)
    assert(tasks.is_running('process'))
    assert(not tasks.is_running('other'))
    assert(vim.wait(3000, function()
        return done ~= nil
    end, 10))
    equal(done, true)
    assert(not tasks.is_running('process'))
    local one = tasks.terminal({ argv = { 'sleep', '20' }, cwd = base, root = 'one' })
    local two = tasks.terminal({ argv = { 'sleep', '20' }, cwd = base, root = 'two' })
    assert(tasks.is_running('one') and tasks.is_running('two'))
    assert(tasks.stop('one'))
    assert(vim.wait(2000, function()
        return not tasks.is_running('one')
    end, 10))
    assert(tasks.is_running('two'))
    tasks.stop('two')
    assert(vim.wait(2000, function()
        return not tasks.is_running()
    end, 10))
    local shell = tasks.terminal({ argv = { 'sleep', '20' }, cwd = base, root = 'shell', track = false })
    assert(not tasks.is_running('shell'))
    vim.fn.jobstop(shell)
    assert(one > 0 and two > 0)
end)

print(string.format('All %d architecture regression groups passed', count))
vim.cmd('qa!')
