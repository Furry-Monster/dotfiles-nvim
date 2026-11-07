local M = {}
local shell

function M.root()
    return require('core.context').resolve().root
end

function M.terminal(argv)
    local ctx = require('core.context').resolve()
    local job = require('core.tasks').terminal({
        argv = argv or vim.o.shell,
        cwd = ctx.root,
        root = ctx.root,
        track = argv ~= nil, -- An interactive project shell is not a build/run task.
    })
    if job and not argv then
        shell = { buffer = vim.api.nvim_get_current_buf(), job = job }
        vim.bo[shell.buffer].bufhidden = 'hide'
    end
    return job
end

function M.toggle()
    if
        not shell
        or not vim.api.nvim_buf_is_valid(shell.buffer)
        or vim.fn.jobwait({ shell.job }, 0)[1] ~= -1
    then
        return M.terminal()
    end

    local win = vim.fn.bufwinid(shell.buffer)
    if win ~= -1 then
        if #vim.api.nvim_tabpage_list_wins(0) == 1 then
            vim.api.nvim_win_call(win, function()
                vim.cmd.enew()
            end)
        else
            vim.api.nvim_win_hide(win)
        end
        return
    end

    vim.cmd('botright 12split')
    vim.api.nvim_win_set_buf(0, shell.buffer)
    vim.cmd.startinsert()
end

function M.run()
    local ft = vim.bo.filetype
    local exe = ({ sh = 'bash', ps1 = 'pwsh' })[ft]
    if not exe then
        return vim.notify('Only Bash / PowerShell scripts are supported')
    end
    if vim.fn.executable(exe) ~= 1 then
        return vim.notify(exe .. ' is not installed', vim.log.levels.ERROR)
    end
    if vim.api.nvim_buf_get_name(0) == '' then
        return vim.notify('Save the script first')
    end
    vim.cmd.update()
    local file = vim.api.nvim_buf_get_name(0)
    M.terminal(ft == 'ps1' and { exe, '-NoLogo', '-NoProfile', '-File', file } or { exe, file })
end

return M
