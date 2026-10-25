local M = {}

function M.setup()
    local registry = require('core.registry')
    -- Filetype integration must be available even if LSP is never loaded.
    registry.each('languages', function(language)
        if language.setup then
            language.setup()
        end
    end)
    registry.each('builders', function(builder)
        if builder.setup then
            builder.setup()
        end
    end)
    registry.each('workflows', function() end)
    require('core.tasks').setup()
    local actions = require('core.actions')
    local bindings = {
        cb = { 'build', 'Build project' },
        cc = { 'check', 'Check project' },
        cC = { 'lint', 'Lint project' },
        cg = { 'configure', 'Configure project' },
        cT = { 'test', 'Test project' },
        cR = { 'run', 'Run project' },
        cd = { 'debug', 'Debug project' },
        cx = { 'stop', 'Stop build task' },
        cp = { 'configure_preset', 'Configure preset' },
        cP = { 'build_preset', 'Build preset' },
        ct = { 'build_target', 'Build target' },
        cl = { 'launch_target', 'Launch target' },
    }
    for key, binding in pairs(bindings) do
        vim.keymap.set('n', '<leader>' .. key, function()
            actions.execute(binding[1])
        end, { desc = binding[2] })
    end
    vim.keymap.set('n', '<F5>', function()
        actions.execute('debug')
    end, { desc = 'Debug project / continue' })
    vim.api.nvim_create_user_command('ProjectInfo', function()
        local ok, ctx = pcall(require('core.context').resolve)
        if not ok then
            return vim.notify(tostring(ctx), vim.log.levels.ERROR)
        end
        vim.notify(vim.inspect({
            root = ctx.root,
            workflow = ctx.workflow,
            builder = ctx.builder_name,
            project = ctx.project,
            run = ctx.run,
        }))
    end, {})
    vim.api.nvim_create_user_command('ProjectAction', function(opts)
        actions.execute(opts.args)
    end, {
        nargs = 1,
        complete = function()
            local ok, ctx = pcall(require('core.context').resolve)
            return ok and actions.names(ctx) or {}
        end,
    })
end

return M
