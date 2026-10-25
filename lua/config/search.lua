-- Shared search policy. Paths remain scoped by core.context, never by a global :cd.
local M = { excluded_directories = { 'build', 'out', 'target', 'third_party', 'vendor' } }

function M.ripgrep_args()
    local args = {}
    for _, directory in ipairs(M.excluded_directories) do
        args[#args + 1] = '--glob=!**/' .. directory .. '/**'
    end
    return args
end

function M.ignore_patterns()
    local patterns = {}
    for _, directory in ipairs(M.excluded_directories) do
        local escaped = vim.pesc(directory)
        vim.list_extend(patterns, { '^' .. escaped .. '/', '/' .. escaped .. '/' })
    end
    return patterns
end

return M
