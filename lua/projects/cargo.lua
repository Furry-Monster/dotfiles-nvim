local M = {}

M.path = require('core.project').path

function M.root(bufnr)
    bufnr = bufnr or 0
    local explicit = require('core.project').explicit_root(bufnr)
    if explicit and vim.fn.filereadable(explicit .. '/Cargo.toml') == 1 then
        return explicit
    end
    local crate = vim.fs.root(bufnr, { 'Cargo.toml' })
    if not crate then
        return nil
    end
    if vim.fn.executable('cargo') == 1 then
        local result = vim.system(
            { 'cargo', 'locate-project', '--workspace', '--message-format', 'plain' },
            { cwd = crate, text = true, env = { RUSTUP_AUTO_INSTALL = '0' } }
        ):wait(3000)
        if result.code == 0 then
            return vim.fs.dirname(vim.trim(result.stdout))
        end
    end
    return crate
end

---@param ctx ProjectContext
function M.options(ctx)
    local check = require('core.validate')
    local cfg = vim.tbl_deep_extend('force', { features = {}, env = {}, debug = {} }, ctx.build)
    cfg.cargoArgs = cfg.args or {}
    cfg.run, cfg.debug = ctx.run, ctx.debug
    local path = ctx.root .. '/.nvim/project.json: build'
    if cfg.target ~= nil then
        check.expect(cfg.target, 'string', path .. '.target')
    end
    if cfg.noDefaultFeatures ~= nil then
        check.expect(cfg.noDefaultFeatures, 'boolean', path .. '.noDefaultFeatures')
    end
    check.strings(cfg.features, path .. '.features')
    for _, arg in ipairs(cfg.cargoArgs) do
        assert(
            arg ~= '--target' and not arg:match('^%-%-target='),
            path .. ': use target instead of args --target'
        )
    end
    if cfg.target and cfg.target:match('%.json$') then
        cfg.target = M.path(ctx.root, cfg.target)
    end
    return cfg
end

function M.args(cfg, command, extra, json, target_override)
    local args = { 'cargo', command }
    if target_override or cfg.target then
        vim.list_extend(args, { '--target', target_override or cfg.target })
    end
    if #cfg.features > 0 then
        vim.list_extend(args, { '--features', table.concat(cfg.features, ',') })
    end
    if cfg.noDefaultFeatures then
        table.insert(args, '--no-default-features')
    end
    vim.list_extend(args, cfg.cargoArgs)
    if json then
        table.insert(args, '--message-format=json')
    end
    vim.list_extend(args, extra or {})
    return args
end

return M
