local M = {}

function M.setup(buffer)
    for _, direction in ipairs({
        { 'h', 'Left', 'left' },
        { 'j', 'Down', 'down' },
        { 'k', 'Up', 'up' },
        { 'l', 'Right', 'right' },
    }) do
        for _, key in ipairs({ '<C-' .. direction[1] .. '>', '<C-' .. direction[2] .. '>' }) do
            local opts = { buffer = buffer, silent = true, desc = 'Focus window ' .. direction[3] }
            vim.keymap.set('n', key, '<C-w>' .. direction[1], opts)
            vim.keymap.set('t', key, '<C-\\><C-n><C-w>' .. direction[1], opts)
        end
    end
end

return M
