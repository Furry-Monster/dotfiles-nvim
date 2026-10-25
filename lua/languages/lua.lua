local M = {
    filetypes = { 'lua' },
    tools = { 'lua-language-server', 'stylua' },
    formatters = { lua = { 'stylua' } },
    treesitter = { 'lua' },
}

function M.settings(root)
    local settings = { telemetry = { enable = false }, workspace = { checkThirdParty = false } }
    -- Neovim-specific defaults belong only to this configuration project.
    if
        root
        and vim.fs.normalize(root) == vim.fs.normalize(vim.fn.stdpath('config'))
        and vim.fn.filereadable(root .. '/.luarc.json') == 0
        and vim.fn.filereadable(root .. '/.luarc.jsonc') == 0
    then
        settings.runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } }
        settings.diagnostics = { globals = { 'vim' } }
        settings.workspace.library = { vim.env.VIMRUNTIME }
    end
    return settings
end

function M.setup_lsp()
    vim.lsp.config('lua_ls', {
        cmd = { 'lua-language-server' },
        before_init = function(_, config)
            config.settings =
                vim.tbl_deep_extend('force', config.settings or {}, { Lua = M.settings(config.root_dir) })
        end,
    })
    if vim.fn.executable('lua-language-server') == 1 then
        vim.lsp.enable('lua_ls')
    end
end

return M
