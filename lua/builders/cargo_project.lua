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

local function strings(value, name)
    assert(type(value) == 'table' and vim.islist(value), name .. ' must be an array')
    for _, item in ipairs(value) do
        assert(type(item) == 'string', name .. ' must contain strings')
    end
end

function M.load(root)
    assert(root, 'Open a Cargo project with Cargo.toml')
    local data = require('core.project').load(root)
    local cfg = vim.tbl_deep_extend('force', { features = {}, env = {}, debug = {} }, data.build or {})
    cfg.cargoArgs = cfg.args or {}
    cfg.run = require('core.project').runtime({ root = root, project = data })
    cfg.debug = data.debug or {}
    assert(cfg.target == nil or type(cfg.target) == 'string', 'target must be a string')
    assert(
        cfg.noDefaultFeatures == nil or type(cfg.noDefaultFeatures) == 'boolean',
        'noDefaultFeatures must be boolean'
    )
    strings(cfg.cargoArgs, 'cargoArgs')
    strings(cfg.features, 'features')
    strings(cfg.run.args, 'run.args')
    strings(cfg.debug.buildArgs or {}, 'debug.buildArgs')
    assert(cfg.run.cwd == nil or type(cfg.run.cwd) == 'string', 'run.cwd must be a string')
    for _, arg in ipairs(cfg.cargoArgs) do
        assert(
            arg ~= '--target' and not arg:match('^%-%-target='),
            'Use the target field instead of cargoArgs --target'
        )
    end
    assert(type(cfg.env) == 'table', 'build.env must be an object')
    for key, value in pairs(cfg.env) do
        assert(type(key) == 'string' and type(value) == 'string', 'env must map names to strings')
    end
    if cfg.target and cfg.target:match('%.json$') then
        cfg.target = M.path(root, cfg.target)
    end
    cfg.run.cwd = cfg.run.cwd and M.path(root, cfg.run.cwd) or root
    return cfg
end

function M.args(root, command, extra, json, target_override)
    local cfg = M.load(root)
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
