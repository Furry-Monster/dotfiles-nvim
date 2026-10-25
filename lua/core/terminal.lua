local M = {}

function M.root()
    return require('core.workflow').context().root
end

function M.terminal(argv)
    return require('core.tasks').terminal({ argv = argv or vim.o.shell, cwd = M.root() })
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
