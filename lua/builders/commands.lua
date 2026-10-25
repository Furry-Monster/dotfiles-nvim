local M = { actions = {} }

function M.run_task(ctx, task)
    assert(type(task.argv) == 'table' and #task.argv > 0, 'A task needs an argv array')
    for _, arg in ipairs(task.argv) do
        assert(type(arg) == 'string', 'Task arguments must be strings')
    end
    local opts = {
        argv = task.argv,
        root = ctx.root,
        cwd = task.cwd and require('core.project').path(ctx.root, task.cwd) or ctx.root,
        env = vim.tbl_extend('force', ctx.build.env, task.env or {}),
    }
    if task.terminal then
        return require('core.tasks').terminal(opts)
    end
    if task.parser then
        opts.parse = assert(
            require('core.registry').get('builders', task.parser).parse,
            'Provider has no output parser'
        )
    else
        local efm = task.errorformat or vim.o.errorformat
        opts.parse = function(stdout, stderr)
            local lines = { '__NVIM_TASK_ROOT__' .. opts.cwd }
            vim.list_extend(lines, vim.split(stdout .. '\n' .. stderr, '\n'))
            return vim.fn.getqflist({ lines = lines, efm = '%D__NVIM_TASK_ROOT__%f,' .. efm }).items
        end
    end
    return require('core.tasks').start(opts)
end

M.actions.stop = function(ctx)
    return require('core.tasks').stop(ctx.root)
end
M.actions.debug = function()
    return require('core.debug').continue()
end

return M
