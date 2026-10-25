local M = {}

-- Precedence is deliberate: external policy > project task > active service > provider.
function M.dispatch(ctx, action, args)
    if ctx.external[action] then
        return vim.notify(
            ctx.workflow .. ': ' .. action .. ' is handled in ' .. (ctx.profile.external_handler or 'tmux')
        )
    end
    if ctx.tasks[action] then
        return require('builders.commands').run_task(ctx, ctx.tasks[action])
    end
    if action == 'stop' and require('core.tasks').is_running(ctx.root) then
        return require('core.tasks').stop(ctx.root)
    end
    if action == 'debug' and require('core.debug').is_active() then
        return require('core.debug').continue()
    end
    local handler = ctx.builder and ctx.builder.actions[action]
    if handler then
        return handler(ctx, args)
    end
    if action == 'debug' then
        return require('core.debug').continue()
    end
    return vim.notify('No ' .. action .. ' action for ' .. (ctx.builder_name or 'this project'))
end

-- UI boundary: report failures here; internal dispatch remains directly testable.
function M.execute(action, opts)
    opts = opts or {}
    local ok, result = pcall(function()
        local ctx = require('core.context').resolve(opts.bufnr, { builder = opts.builder })
        return M.dispatch(ctx, action, opts.args)
    end)
    if not ok then
        vim.notify(tostring(result), vim.log.levels.ERROR)
        return nil, result
    end
    return result
end

function M.names(ctx)
    local names = {}
    require('core.registry').each('builders', function(provider)
        for action in pairs(provider.actions) do
            names[action] = true
        end
    end)
    for action in pairs(ctx.tasks) do
        names[action] = true
    end
    local keys = vim.tbl_keys(names)
    table.sort(keys)
    return keys
end

return M
