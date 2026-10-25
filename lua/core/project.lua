local M = {}
local check = require('core.validate')

function M.path(root, path)
    if path:match('^[/\\]') or path:match('^%a:[/\\]') then
        return vim.fs.normalize(path)
    end
    return vim.fs.normalize(vim.fs.joinpath(root, path))
end

function M.validate(data, path)
    path = path or 'project'
    check.object(data, path)
    for _, field in ipairs({ 'build', 'configure', 'run', 'debug' }) do
        if data[field] ~= nil then
            check.command_options(data[field], path .. '.' .. field)
        end
    end
    if data.debug and data.debug.buildArgs ~= nil then
        check.strings(data.debug.buildArgs, path .. '.debug.buildArgs')
    end
    for field, kind in pairs({ workflow = 'workflows', builder = 'builders' }) do
        local value = data[field]
        if value ~= nil and not (field == 'builder' and value == false) then
            check.expect(value, 'string', path .. '.' .. field)
            assert(
                vim.tbl_contains(require('core.registry').names(kind), value),
                path .. '.' .. field .. ': unregistered module ' .. value
            )
        end
    end
    if data.external ~= nil then
        check.map(data.external, 'boolean', path .. '.external')
    end
    if data.languages ~= nil then
        check.object(data.languages, path .. '.languages')
        for name, options in pairs(data.languages) do
            check.object(options, path .. '.languages.' .. name)
        end
    end
    if data.tasks ~= nil then
        check.object(data.tasks, path .. '.tasks')
        for name, task in pairs(data.tasks) do
            local task_path = path .. '.tasks.' .. name
            check.command_options(task, task_path)
            check.strings(task.argv, task_path .. '.argv')
            assert(#task.argv > 0, task_path .. '.argv must not be empty')
            if task.terminal ~= nil then
                check.expect(task.terminal, 'boolean', task_path .. '.terminal')
            end
            if task.parser ~= nil then
                check.expect(task.parser, 'string', task_path .. '.parser')
                assert(
                    vim.tbl_contains(require('core.registry').names('builders'), task.parser),
                    task_path .. '.parser: unregistered provider'
                )
            end
            if task.errorformat ~= nil then
                check.expect(task.errorformat, 'string', task_path .. '.errorformat')
            end
        end
    end
    return data
end

function M.load(root)
    local file = root .. '/.nvim/project.json'
    if vim.fn.filereadable(file) == 0 then
        return {}
    end
    local content = table.concat(vim.fn.readfile(file), '\n')
    local ok, data = pcall(vim.json.decode, content)
    assert(ok, file .. ': invalid JSON: ' .. tostring(data))
    assert(content:match('^%s*{') and type(data) == 'table', file .. ' must contain a JSON object')
    return M.validate(data, file)
end

function M.explicit_root(bufnr)
    return vim.fs.root(bufnr or 0, function(name, parent)
        return name == '.nvim' and vim.fn.filereadable(parent .. '/.nvim/project.json') == 1
    end)
end

function M.runtime(ctx)
    if ctx.run then
        return ctx.run
    end
    local run = vim.tbl_deep_extend('force', (ctx.profile or {}).runtime or {}, ctx.project.run or {})
    return {
        cwd = run.cwd and M.path(ctx.root, run.cwd) or ctx.root,
        args = run.args or {},
        env = vim.tbl_extend('force', (ctx.project.build or {}).env or {}, run.env or {}),
    }
end

function M.normalize(ctx)
    local data = ctx.project
    ctx.build = vim.tbl_deep_extend('force', { args = {}, env = {} }, data.build or {})
    ctx.configure = vim.tbl_deep_extend('force', { args = {} }, data.configure or {})
    ctx.debug = vim.deepcopy(data.debug or {})
    ctx.external = vim.tbl_extend('force', ctx.profile.external or {}, data.external or {})
    ctx.tasks = vim.deepcopy(data.tasks or {})
    ctx.run_configured = data.run ~= nil or ctx.profile.runtime ~= nil
    ctx.run = M.runtime(ctx)
    return ctx
end

return M
