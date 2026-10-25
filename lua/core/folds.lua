local M = {}

function M.apply(win)
    if not vim.api.nvim_win_is_valid(win) then
        return
    end
    local bufnr = vim.api.nvim_win_get_buf(win)
    -- Quickfix, terminal, search UIs and other plugins own their window settings.
    if vim.bo[bufnr].buftype ~= '' or vim.bo[bufnr].filetype == '' or vim.wo[win].diff then
        return
    end
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    local query_ok, query
    if ok and parser then
        query_ok, query = pcall(vim.treesitter.query.get, parser:lang(), 'folds')
    end
    local method = query_ok and query and 'expr' or 'indent'
    local expr = method == 'expr' and 'v:lua.vim.treesitter.foldexpr()' or '0'
    local options = vim.wo[win][0]
    -- Avoid resetting existing fold state on every window entry.
    if options.foldexpr ~= expr then
        options.foldexpr = expr
    end
    if options.foldmethod ~= method then
        options.foldmethod = method
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup('WorkflowFolds', { clear = true })
    vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
        group = group,
        desc = 'Use syntax folds when available, otherwise indentation folds',
        callback = function(event)
            for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
                M.apply(win)
            end
        end,
    })
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        M.apply(win)
    end
end

return M
