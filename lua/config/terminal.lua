local M = { sessions = {} }

function M.open(argv, owner, opts)
    opts = opts or {}
    if type(argv) == "string" then argv = { argv } end
    if not argv[1] or vim.fn.executable(argv[1]) == 0 then
        vim.notify("终端程序未安装: " .. tostring(argv[1]), vim.log.levels.ERROR)
        return
    end
    local root = opts.cwd or require("project.root").get()
    local key = owner .. ":" .. root
    local old = M.sessions[key]
    if old and vim.api.nvim_buf_is_valid(old.buf) then
        local wins = vim.fn.win_findbuf(old.buf)
        if wins[1] then vim.api.nvim_set_current_win(wins[1]) else
            vim.cmd("botright vsplit")
            vim.api.nvim_win_set_buf(0, old.buf)
        end
        vim.cmd.startinsert()
        return old
    end
    local source = vim.api.nvim_get_current_buf()
    if opts.workspace then
        vim.cmd.tabnew()
        vim.api.nvim_win_set_buf(0, source)
        vim.t.workbench_root = root
        vim.cmd("botright vsplit")
    else
        vim.cmd("botright 14split")
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    local session = { buf = buf, owner = owner, cwd = root }
    M.sessions[key] = session
    session.job = vim.fn.jobstart(argv, {
        term = true,
        cwd = root,
        on_exit = function()
            vim.schedule(function()
                if M.sessions[key] == session then M.sessions[key] = nil end
            end)
        end,
    })
    if session.job <= 0 then
        M.sessions[key] = nil
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.notify("终端启动失败", vim.log.levels.ERROR)
        return
    end
    vim.bo[buf].bufhidden = "hide"
    vim.b[buf].workbench_root = root
    vim.cmd.startinsert()
    return session
end

function M.stop(owner)
    local remove = {}
    for key, session in pairs(M.sessions) do
        if session.owner == owner then
            table.insert(remove, key)
            if session.job and session.job > 0 then pcall(vim.fn.jobstop, session.job) end
            if vim.api.nvim_buf_is_valid(session.buf) then
                vim.api.nvim_buf_delete(session.buf, { force = true })
            end
        end
    end
    for _, key in ipairs(remove) do M.sessions[key] = nil end
end

return M
