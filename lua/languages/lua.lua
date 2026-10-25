local M = {
    filetypes = { 'lua' },
    tools = { 'stylua' },
    formatters = { lua = { 'stylua' } },
    treesitter = { 'lua' },
}

function M.command()
    if vim.fn.executable('lua-language-server') == 1 then
        return { 'lua-language-server' }
    end
    -- The system RPM may split the executable and Lua entry point without a PATH wrapper.
    local binary = '/usr/libexec/lua-language-server/lua-language-server'
    local script = '/usr/share/lua-language-server/main.lua'
    if vim.fn.executable(binary) == 1 and vim.fn.filereadable(script) == 1 then
        return {
            binary,
            script,
            '--logpath=' .. vim.fn.stdpath('state') .. '/lua-language-server',
            '--metapath=' .. vim.fn.stdpath('cache') .. '/lua-language-server/meta',
        }
    end
end

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
    local cmd = M.command()
    if not cmd then
        return
    end
    vim.lsp.config('lua_ls', {
        cmd = cmd,
        before_init = function(_, config)
            config.settings =
                vim.tbl_deep_extend('force', config.settings or {}, { Lua = M.settings(config.root_dir) })
        end,
    })
    vim.lsp.enable('lua_ls')
end

function M.check_health()
    local cmd = M.command()
    if cmd then
        vim.health.ok('Lua language server: ' .. table.concat(cmd, ' '))
    else
        vim.health.warn('Lua language server not found on PATH or in the system RPM layout')
    end
end

return M
