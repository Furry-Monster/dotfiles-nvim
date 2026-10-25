local M = {}
local terminals = {}

local function matches(task, root)
    return root == nil or task.root == root
end

function M.is_running(root)
    if M.active and matches(M.active, root) then
        return true
    end
    for _, task in pairs(terminals) do
        if matches(task, root) then
            return true
        end
    end
    return false
end

function M.terminal(opts)
    vim.cmd('botright 12split')
    vim.cmd.enew()
    local job = vim.fn.jobstart(opts.argv, {
        term = true,
        cwd = opts.cwd,
        env = opts.env,
        on_exit = function(id)
            terminals[id] = nil
        end,
    })
    if job <= 0 then
        return vim.notify('Could not start task', vim.log.levels.ERROR)
    end
    if opts.track ~= false then
        terminals[job] = { root = opts.root or opts.cwd }
    end
    vim.cmd.startinsert()
    return job
end

function M.start(opts, callback)
    callback = callback or function() end
    if M.active then
        vim.notify('A build task is already running; stop it before starting another', vim.log.levels.WARN)
        callback(false, {})
        return
    end
    local title = opts.title or table.concat(opts.argv, ' ')
    vim.notify(title)
    local task = { root = opts.root or opts.cwd }
    M.active = task
    local ok, process = pcall(
        vim.system,
        opts.argv,
        { cwd = opts.cwd, text = true, env = opts.env },
        function(result)
            vim.schedule(function()
                if M.active == task then
                    M.active = nil
                end
                local parsed, items, artifacts =
                    pcall(opts.parse, result.stdout or '', result.stderr or '', opts.cwd)
                if not parsed then
                    vim.notify(tostring(items), vim.log.levels.ERROR)
                    callback(false, {})
                    return
                end
                vim.fn.setqflist({}, ' ', { title = title, items = items })
                local success = result.code == 0
                vim.notify(
                    success and 'Task finished' or ('Task exited: ' .. result.code),
                    success and vim.log.levels.INFO or vim.log.levels.WARN
                )
                if not success then
                    vim.cmd.copen()
                end
                callback(success, artifacts or {})
            end)
        end
    )
    if not ok then
        M.active = nil
        vim.notify(tostring(process), vim.log.levels.ERROR)
        callback(false, {})
        return
    end
    task.process = process
    return process
end

function M.stop(root)
    local stopped = false
    if M.active and M.active.process and matches(M.active, root) then
        M.active.process:kill(2)
        stopped = true
    end
    for id, task in pairs(terminals) do
        if matches(task, root) then
            vim.fn.jobstop(id)
            stopped = true
        end
    end
    return stopped
end

function M.setup()
    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = vim.api.nvim_create_augroup('WorkflowTasks', { clear = true }),
        desc = 'Stop editor-owned tasks on exit',
        callback = function()
            M.stop()
        end,
    })
end

return M
