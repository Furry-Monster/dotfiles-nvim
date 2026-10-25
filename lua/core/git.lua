local M = {}

function M.on_attach(bufnr)
    local git = require('gitsigns')
    local function map(mode, key, action, desc)
        vim.keymap.set(mode, key, action, { buffer = bufnr, silent = true, desc = desc })
    end
    for key, direction in pairs({ [']c'] = 'next', ['[c'] = 'prev' }) do
        map('n', key, function()
            if vim.wo.diff then
                return vim.cmd.normal({ key, bang = true })
            end
            git.nav_hunk(direction)
        end, direction == 'next' and 'Next Git hunk' or 'Previous Git hunk')
    end
    map('n', '<leader>gp', git.preview_hunk, 'Preview Git hunk')
    map('n', '<leader>gs', git.stage_hunk, 'Stage / unstage Git hunk')
    map('n', '<leader>gr', git.reset_hunk, 'Reset Git hunk')
    for key, action in pairs({ ['<leader>gs'] = git.stage_hunk, ['<leader>gr'] = git.reset_hunk }) do
        map('x', key, function()
            local first, last = vim.fn.line('v'), vim.fn.line('.')
            action({ math.min(first, last), math.max(first, last) })
        end, key == '<leader>gs' and 'Stage selected lines' or 'Reset selected lines')
    end
    map('n', '<leader>gb', git.blame_line, 'Git blame for current line')
    map('n', '<leader>gd', git.diffthis, 'Diff file against Git index')
    map({ 'o', 'x' }, 'ih', git.select_hunk, 'Git hunk text object')
end

return M
