local M = {}

function M.expect(value, kind, path)
    assert(type(value) == kind, path .. ' must be a ' .. kind)
end

function M.object(value, path)
    M.expect(value, 'table', path)
    assert(next(value) == nil or not vim.islist(value), path .. ' must be an object')
    for key in pairs(value) do
        assert(type(key) == 'string', path .. ' must have string keys')
    end
end

function M.strings(value, path)
    assert(type(value) == 'table' and vim.islist(value), path .. ' must be an array')
    for index, item in ipairs(value) do
        M.expect(item, 'string', path .. '[' .. index .. ']')
    end
end

function M.map(value, kind, path)
    M.object(value, path)
    for key, item in pairs(value) do
        M.expect(item, kind, path .. '.' .. key)
    end
end

function M.command_options(value, path)
    M.object(value, path)
    if value.args ~= nil then
        M.strings(value.args, path .. '.args')
    end
    if value.env ~= nil then
        M.map(value.env, 'string', path .. '.env')
    end
    if value.cwd ~= nil then
        M.expect(value.cwd, 'string', path .. '.cwd')
    end
end

return M
