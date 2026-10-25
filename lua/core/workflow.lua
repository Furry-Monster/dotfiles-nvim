local M = {}
local registry = require('config.modules')

local function registered(list, name)
    assert(vim.tbl_contains(list, name), 'Unregistered module: ' .. tostring(name))
    return name
end

function M.context(bufnr)
    bufnr = bufnr or 0
    local project = require('core.project')
    local root = project.explicit_root(bufnr)
    local data = root and project.load(root) or {}
    local builder_name = data.builder
    if builder_name then
        registered(registry.builders, builder_name)
    else
        local candidates = {}
        for _, name in ipairs(registry.builders) do
            local builder = require('builders.' .. name)
            local detected = builder.detect and builder.detect(bufnr)
            if detected then
                table.insert(candidates, {
                    name = name,
                    root = detected,
                    matches = vim.tbl_contains(builder.filetypes or {}, vim.bo[bufnr].filetype),
                })
            end
        end
        table.sort(candidates, function(a, b)
            if a.matches ~= b.matches then
                return a.matches
            end
            if #a.root ~= #b.root then
                return #a.root > #b.root
            end
            return a.name < b.name
        end)
        if candidates[1] then
            builder_name = candidates[1].name
            root = root or candidates[1].root
        end
    end
    root = root or vim.fs.root(bufnr, { '.git' }) or vim.fn.getcwd()
    local profile_name = data.workflow or 'default'
    registered(registry.workflows, profile_name)
    return {
        root = root,
        project = data,
        workflow = profile_name,
        profile = require('workflows.' .. profile_name),
        builder_name = builder_name,
        builder = builder_name and require('builders.' .. builder_name) or nil,
        bufnr = bufnr,
        filetype = vim.bo[bufnr].filetype,
    }
end

function M.execute(action, opts)
    local ok, err = pcall(function()
        local ctx = M.context()
        opts = opts or {}
        if opts.builder then
            registered(registry.builders, opts.builder)
            ctx.builder_name = opts.builder
            ctx.builder = require('builders.' .. opts.builder)
            if not require('core.project').explicit_root(ctx.bufnr) and ctx.builder.detect then
                ctx.root = ctx.builder.detect(ctx.bufnr) or ctx.root
            end
        end
        local external = vim.tbl_extend('force', ctx.profile.external or {}, ctx.project.external or {})
        if external[action] then
            return vim.notify(ctx.workflow .. ': ' .. action .. ' is handled in tmux')
        end
        local task = (ctx.project.tasks or {})[action]
        if task then
            return require('builders.commands').run_task(ctx, task)
        end
        if action == 'stop' and require('core.tasks').active then
            return require('core.tasks').stop()
        end
        if action == 'debug' and require('dap').session() then
            return require('dap').continue()
        end
        local handler = ctx.builder and ctx.builder.actions[action]
        if not handler then
            if action == 'debug' then
                return require('dap').continue()
            end
            return vim.notify('No ' .. action .. ' action for ' .. (ctx.builder_name or 'this project'))
        end
        return handler(ctx, opts.args)
    end)
    if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
    end
end

function M.setup()
    for _, name in ipairs(registry.builders) do
        local builder = require('builders.' .. name)
        if builder.setup then
            builder.setup()
        end
    end
    local actions = {
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
    for key, definition in pairs(actions) do
        vim.keymap.set('n', '<leader>' .. key, function()
            M.execute(definition[1])
        end, { desc = definition[2] })
    end
    vim.keymap.set('n', '<F5>', function()
        M.execute('debug')
    end, { desc = 'Debug project / continue' })
    vim.api.nvim_create_user_command('ProjectInfo', function()
        local ctx = M.context()
        vim.notify(vim.inspect({
            root = ctx.root,
            workflow = ctx.workflow,
            builder = ctx.builder_name,
            project = ctx.project,
        }))
    end, {})
    vim.api.nvim_create_user_command('ProjectAction', function(opts)
        M.execute(opts.args)
    end, {
        nargs = 1,
        complete = function()
            local names = {}
            for _, name in ipairs(registry.builders) do
                for action in pairs(require('builders.' .. name).actions) do
                    names[action] = true
                end
            end
            for action in pairs(M.context().project.tasks or {}) do
                names[action] = true
            end
            local keys = vim.tbl_keys(names)
            table.sort(keys)
            return keys
        end,
    })
end

return M
