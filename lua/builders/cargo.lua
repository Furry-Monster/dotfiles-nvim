local M = {}

function M.parse(stdout, stderr, root)
    local items, artifacts, seen, logs = {}, {}, {}, {}
    local severity = { error = 'E', warning = 'W', note = 'I', help = 'H' }
    for line in (stdout or ''):gmatch('[^\r\n]+') do
        local ok, message = pcall(vim.json.decode, line)
        if ok and type(message) == 'table' and message.reason == 'compiler-message' then
            local diagnostic = message.message
            local primary
            for _, span in ipairs(diagnostic.spans or {}) do
                if span.is_primary then
                    primary = span
                    break
                end
            end
            local text = diagnostic.message
            if type(diagnostic.code) == 'table' and diagnostic.code.code then
                text = diagnostic.code.code .. ': ' .. text
            end
            local item = { text = text, type = severity[diagnostic.level] or 'I', valid = primary and 1 or 0 }
            if primary then
                item.filename = require('core.project').path(root, primary.file_name)
                item.lnum, item.col = primary.line_start, primary.column_start
                item.end_lnum, item.end_col = primary.line_end, primary.column_end
            end
            table.insert(items, item)
        elseif ok and type(message) == 'table' and message.reason == 'compiler-artifact' then
            local exe = message.executable
            if type(exe) == 'string' and not seen[exe] then
                local kinds = message.target.kind or {}
                if
                    message.profile.test
                    or vim.tbl_contains(kinds, 'bin')
                    or vim.tbl_contains(kinds, 'example')
                then
                    seen[exe] = true
                    table.insert(
                        artifacts,
                        { path = exe, name = message.target.name, test = message.profile.test }
                    )
                end
            end
        elseif not (ok and type(message) == 'table' and message.reason) then
            table.insert(logs, line)
        end
    end
    for line in (stderr or ''):gmatch('[^\r\n]+') do
        table.insert(logs, line)
    end
    -- Keep link errors, Cargo failures and test output even when no source span exists.
    for _, line in ipairs(logs) do
        table.insert(items, { text = line, valid = 0 })
    end
    return items, artifacts
end

function M.start(ctx, args, callback)
    local cfg = require('projects.cargo').options(ctx)
    return require('core.tasks').start({
        argv = args,
        cwd = ctx.root,
        root = ctx.root,
        parse = M.parse,
        env = vim.tbl_extend('force', { CARGO_TERM_COLOR = 'never', RUSTUP_AUTO_INSTALL = '0' }, cfg.env),
    }, callback)
end

M.filetypes = { 'rust', 'toml' }
M.tools = { 'cargo' }
M.detect = require('projects.cargo').root

function M.command(ctx, command, extra)
    local project = require('projects.cargo')
    local cfg = project.options(ctx)
    local args = project.args(cfg, command, extra)
    if command == 'run' or command == 'test' then
        if command == 'run' and #cfg.run.args > 0 then
            local separator = vim.fn.index(args, '--')
            if separator < 0 then
                table.insert(args, '--')
            end
            vim.list_extend(args, cfg.run.args)
        end
        if command == 'run' and cfg.run.cwd ~= ctx.root then
            -- Keep Cargo pointed at the project when running from an asset directory.
            table.insert(args, 3, '--manifest-path')
            table.insert(args, 4, vim.fs.joinpath(ctx.root, 'Cargo.toml'))
        end
        return require('core.tasks').terminal({
            argv = args,
            root = ctx.root,
            cwd = command == 'run' and cfg.run.cwd or ctx.root,
            env = vim.tbl_extend('force', { RUSTUP_AUTO_INSTALL = '0' }, cfg.run.env),
        })
    end
    return M.start(ctx, project.args(cfg, command, extra, true))
end

M.stop = function(ctx)
    return require('core.tasks').stop(ctx and ctx.root)
end
M.actions = {
    build = function(ctx, args)
        return M.command(ctx, 'build', args)
    end,
    check = function(ctx, args)
        return M.command(ctx, 'check', args)
    end,
    lint = function(ctx, args)
        return M.command(ctx, 'clippy', args)
    end,
    test = function(ctx, args)
        return M.command(ctx, 'test', args)
    end,
    run = function(ctx, args)
        return M.command(ctx, 'run', args)
    end,
    stop = M.stop,
    debug = function(ctx)
        local cfg = require('projects.cargo').options(ctx)
        if cfg.target and cfg.target ~= require('toolchains.rust').info(ctx.root) then
            return vim.notify('This target is not a host executable; use your external debugging workflow')
        end
        return require('dap').continue()
    end,
}

M.debug_configurations = function(ctx)
    return require('builders.cargo_debug').configurations(ctx)
end

function M.setup()
    vim.api.nvim_create_user_command('Cargo', function(opts)
        local args = vim.deepcopy(opts.fargs)
        local command = table.remove(args, 1) or 'check'
        if not vim.tbl_contains({ 'build', 'check', 'clippy', 'test', 'run' }, command) then
            return vim.notify('Supported: Cargo build/check/clippy/test/run')
        end
        require('core.actions').execute(
            ({ clippy = 'lint' })[command] or command,
            { builder = 'cargo', args = args }
        )
    end, {
        nargs = '*',
        complete = function()
            return { 'build', 'check', 'clippy', 'test', 'run' }
        end,
    })
    vim.api.nvim_create_user_command('CargoStop', function()
        require('core.actions').execute('stop', { builder = 'cargo' })
    end, {})
end

return M
