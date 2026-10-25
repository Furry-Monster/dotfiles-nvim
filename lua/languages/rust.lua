local M = {
    filetypes = { 'rust' },
    native_debug = true,
    tools = { 'rustc', 'cargo', 'rust-analyzer', 'rustfmt', 'clippy-driver', 'rustup' },
    formatters = { rust = { 'rustfmt', lsp_format = 'prefer' } },
    formatter_options = { rustfmt = { env = { RUSTUP_AUTO_INSTALL = '0' } } },
    treesitter = { 'rust', 'toml' },
}

function M.settings(root)
    local data = require('core.project').load(root)
    local settings = {
        cargo = { buildScripts = { enable = true } },
        procMacro = { enable = true },
        check = { command = 'check' },
        lens = { enable = false },
    }
    if not data.builder or data.builder == 'cargo' then
        local cfg = require('builders.cargo_project').load(root)
        settings.cargo.target = cfg.target
        if cfg.target then
            settings.check.targets = { cfg.target }
        end
        settings.cargo.features = cfg.features
        settings.cargo.noDefaultFeatures = cfg.noDefaultFeatures or false
        if next(cfg.env) then
            settings.cargo.extraEnv = cfg.env
        end
        settings.check.extraArgs = cfg.cargoArgs
    end
    settings = vim.tbl_deep_extend('force', settings, ((data.languages or {}).rust or {}).analyzer or {})
    if settings.linkedProjects then
        for index, path in ipairs(settings.linkedProjects) do
            if type(path) == 'string' then
                settings.linkedProjects[index] = require('core.project').path(root, path)
            end
        end
    end
    return settings
end

function M.setup_lsp()
    vim.lsp.config('rust_analyzer', {
        cmd = { 'rust-analyzer' },
        cmd_env = { RUSTUP_AUTO_INSTALL = '0' },
        root_dir = function(bufnr, on_dir)
            local root = require('core.project').explicit_root(bufnr)
                or vim.fs.root(bufnr, { 'rust-project.json' })
                or require('builders.cargo_project').root(bufnr)
            if root then
                on_dir(root)
            end
        end,
        before_init = function(params, config)
            local settings = M.settings(config.root_dir)
            config.settings = { ['rust-analyzer'] = settings }
            params.initializationOptions = settings
        end,
    })
    if vim.fn.executable('rust-analyzer') == 1 then
        vim.lsp.enable('rust_analyzer')
    end
    vim.api.nvim_create_user_command('RustExpandMacro', M.expand_macro, {})
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('WorkflowRust', { clear = true }),
        pattern = 'rust',
        callback = function(event)
            vim.keymap.set(
                'n',
                '<leader>cm',
                M.expand_macro,
                { buffer = event.buf, desc = 'Expand Rust macro' }
            )
        end,
    })
end

function M.expand_macro()
    local client = vim.lsp.get_clients({ bufnr = 0, name = 'rust_analyzer' })[1]
    if not client then
        return vim.notify('rust-analyzer is not attached')
    end
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    client:request('rust-analyzer/expandMacro', params, function(err, result)
        if err then
            return vim.notify(err.message, vim.log.levels.ERROR)
        end
        if not result then
            return vim.notify('No macro at cursor')
        end
        vim.lsp.util.open_floating_preview(
            vim.split(result.expansion, '\n'),
            'rust',
            { border = 'rounded', title = result.name }
        )
    end, 0)
end

function M.toolchain(root)
    local opts = { cwd = root, text = true, env = { RUSTUP_AUTO_INSTALL = '0' } }
    local result = vim.system({ 'rustc', '-vV' }, opts):wait(3000)
    assert(result.code == 0, 'Cannot query project rustc; check rust-toolchain.toml in tmux')
    local host = result.stdout:match('host: ([^\r\n]+)')
    assert(host, 'rustc did not report its host target')
    local sysroot = vim.system({ 'rustc', '--print', 'sysroot' }, opts):wait(3000)
    return host, sysroot.code == 0 and vim.trim(sysroot.stdout) or nil
end

function M.enrich_debug(config, ctx)
    local _, sysroot = M.toolchain(ctx.root)
    if config.type == 'gdb' then
        config.type, config.rustRoot = 'rust_gdb', ctx.root
    elseif config.type == 'lldb' and sysroot then
        local printers = sysroot .. '/lib/rustlib/etc/lldb_lookup.py'
        if vim.fn.filereadable(printers) == 1 then
            config.initCommands = config.initCommands or {}
            table.insert(config.initCommands, 'command script import ' .. string.format('%q', printers))
        end
    end
    return config
end

function M.setup_debug()
    local dap = require('dap')
    dap.adapters.rust_gdb = function(callback, config)
        local adapter = vim.deepcopy(dap.adapters.gdb)
        local _, sysroot = M.toolchain(config.rustRoot)
        if sysroot then
            local printers = sysroot .. '/lib/rustlib/etc'
            if vim.fn.isdirectory(printers) == 1 then
                vim.list_extend(
                    adapter.args,
                    { '--directory=' .. printers, '-iex', 'add-auto-load-safe-path ' .. printers }
                )
            end
        end
        callback(adapter)
    end
end

return M
