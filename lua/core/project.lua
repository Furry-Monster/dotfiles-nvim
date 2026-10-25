local M = {}

function M.path(root, path)
    if path:match('^[/\\]') or path:match('^%a:[/\\]') then
        return vim.fs.normalize(path)
    end
    return vim.fs.normalize(vim.fs.joinpath(root, path))
end

function M.load(root)
    local file = root .. '/.nvim/project.json'
    if vim.fn.filereadable(file) == 0 then
        return {}
    end
    local content = table.concat(vim.fn.readfile(file), '\n')
    local ok, data = pcall(vim.json.decode, content)
    assert(ok, file .. ': invalid JSON: ' .. tostring(data))
    assert(content:match('^%s*{') and type(data) == 'table', file .. ' must contain a JSON object')
    return data
end

function M.explicit_root(bufnr)
    return vim.fs.root(bufnr or 0, function(name, parent)
        return name == '.nvim' and vim.fn.filereadable(parent .. '/.nvim/project.json') == 1
    end)
end

function M.runtime(ctx)
    local run = vim.tbl_deep_extend('force', (ctx.profile or {}).runtime or {}, ctx.project.run or {})
    return {
        cwd = run.cwd and M.path(ctx.root, run.cwd) or ctx.root,
        args = run.args or {},
        env = vim.tbl_extend('force', (ctx.project.build or {}).env or {}, run.env or {}),
    }
end

return M
