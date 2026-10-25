-- Keep missing plugins visible in :Lazy without registering startup load events.
local function installed_event(plugin)
    return vim.fn.isdirectory(plugin.dir .. '/lua') == 1 and { 'VeryLazy' } or {}
end

return {
    {
        'nvim-mini/mini.surround',
        branch = 'stable',
        event = installed_event,
        opts = {
            mappings = {
                add = 'gsa',
                delete = 'gsd',
                replace = 'gsr',
                find = 'gsf',
                find_left = 'gsF',
                highlight = 'gsh',
                update_n_lines = 'gsn',
            },
        },
    },
    {
        'nvim-mini/mini.ai',
        branch = 'stable',
        event = installed_event,
        opts = { n_lines = 200 },
    },
}
