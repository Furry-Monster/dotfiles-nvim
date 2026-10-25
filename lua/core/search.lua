local M = {}
local policy = require('config.search')

-- Keep project resolution and plugin loading inside the UI error boundary.
local function run(callback)
    local ok, result = pcall(function()
        return callback(require('core.context').resolve().root)
    end)
    if not ok then
        vim.notify(tostring(result), vim.log.levels.ERROR)
        return nil, result
    end
    return result
end

function M.open(picker)
    return run(function(root)
        local opts = { cwd = root }
        if picker == 'find_files' then
            opts.find_command = vim.list_extend({ 'rg', '--files' }, policy.ripgrep_args())
        elseif picker == 'live_grep' or picker == 'grep_string' then
            opts.additional_args = policy.ripgrep_args()
        end
        return require('telescope.builtin')[picker](opts)
    end)
end

function M.resume()
    return run(function(root)
        -- A cached finder's cwd is already captured. Never reuse another project's finder.
        local cached = require('telescope.state').get_global_key('cached_pickers') or {}
        for index, picker in ipairs(cached) do
            if picker.cwd and vim.fs.normalize(tostring(picker.cwd)) == root then
                return require('telescope.builtin').resume({ cache_index = index })
            end
        end
        vim.notify('No previous search for this project')
    end)
end

function M.replace(word)
    return run(function(root)
        return require('grug-far').open({
            engine = 'ripgrep',
            -- Absolute paths pin the search even if CMake later changes the global cwd.
            prefills = {
                paths = vim.fn.fnameescape(root),
                search = word and vim.fn.expand('<cword>') or nil,
            },
        })
    end)
end

return M
