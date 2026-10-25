local M = {
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    native_debug = true,
    tools = { 'clangd', 'clang-format', 'gcc', 'clang' },
    formatters = { c = { 'clang_format' }, cpp = { 'clang_format' } },
    treesitter = { 'c', 'cpp' },
}

function M.setup_lsp()
    local cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--completion-style=detailed',
        '--header-insertion=iwyu',
    }
    local drivers = {}
    for _, name in ipairs({ 'gcc', 'g++', 'clang', 'clang++' }) do
        local path = vim.fn.exepath(name)
        if path ~= '' then
            table.insert(drivers, path)
        end
    end
    if #drivers > 0 then
        table.insert(cmd, '--query-driver=' .. table.concat(drivers, ','))
    end
    vim.lsp.config('clangd', {
        cmd = cmd,
        root_markers = {
            'CMakePresets.json',
            'CMakeUserPresets.json',
            '.clangd',
            'compile_commands.json',
            '.git',
            'CMakeLists.txt',
        },
    })
    if vim.fn.executable('clangd') == 1 then
        vim.lsp.enable('clangd')
    end
    vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
            if vim.lsp.get_client_by_id(event.data.client_id).name == 'clangd' then
                vim.keymap.set(
                    'n',
                    '<leader>cs',
                    '<cmd>LspClangdSwitchSourceHeader<cr>',
                    { buffer = event.buf, desc = 'Switch source/header' }
                )
            end
        end,
    })
end

return M
