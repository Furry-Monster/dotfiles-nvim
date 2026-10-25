local M = {}
local registry = require('core.registry')

---@class ProjectContext
---@field root string
---@field bufnr? integer
---@field filetype string
---@field project table Raw validated project configuration; treat as read-only.
---@field workflow string
---@field profile WorkflowProfile
---@field builder_name? string
---@field builder? BuildProvider
---@field build table
---@field configure table
---@field debug table
---@field run table Resolved cwd, args and environment shared by all consumers.
---@field run_configured boolean
---@field external table<string, boolean>
---@field tasks table

function M.resolve(source, opts)
    source, opts = source or 0, opts or {}
    if source == 0 then
        source = vim.api.nvim_get_current_buf()
    end
    local bufnr = type(source) == 'number' and source or nil
    local filetype = opts.filetype or (bufnr and vim.bo[bufnr].filetype) or ''
    local project = require('core.project')
    local root = project.explicit_root(source)
    local data = root and project.load(root) or {}
    local profile_name = data.workflow
    if not profile_name then
        local best_root
        for _, name in ipairs(registry.names('workflows')) do
            local candidate = registry.get('workflows', name)
            local detected = candidate.detect and candidate.detect(source)
            if detected and (not best_root or #detected > #best_root) then
                profile_name, best_root = name, detected
            end
        end
        root = root or best_root
    end
    profile_name = profile_name or 'default'
    local profile = registry.get('workflows', profile_name)
    local builder_name = opts.builder
    if builder_name == nil then
        builder_name = data.builder
    end
    if builder_name == nil then
        builder_name = profile.default_builder
    end
    if builder_name == false then
        builder_name = nil
    elseif builder_name then
        registry.get('builders', builder_name)
    else
        local candidates = {}
        for _, name in ipairs(registry.names('builders')) do
            local builder = registry.get('builders', name)
            local detected = builder.detect and builder.detect(source)
            if detected then
                table.insert(candidates, {
                    name = name,
                    root = detected,
                    matches = vim.tbl_contains(builder.filetypes or {}, filetype),
                })
            end
        end
        table.sort(candidates, function(a, b)
            if a.matches ~= b.matches then
                return a.matches
            end
            if #a.root ~= #b.root then
                return #a.root > #b.root
            end
            return a.name < b.name
        end)
        if candidates[1] then
            builder_name = candidates[1].name
            root = root or candidates[1].root
        end
    end
    if builder_name and not root then
        local provider = registry.get('builders', builder_name)
        root = provider.detect and provider.detect(source)
    end
    root = root or vim.fs.root(source, { '.git' })
    if not root and type(source) == 'string' then
        root = vim.fn.isdirectory(source) == 1 and source or vim.fs.dirname(source)
    end
    root = root or vim.fn.getcwd()
    local ctx = {
        root = vim.fs.normalize(root),
        project = data,
        workflow = profile_name,
        profile = profile,
        builder_name = builder_name,
        builder = builder_name and registry.get('builders', builder_name) or nil,
        bufnr = bufnr,
        filetype = filetype,
    }
    return project.normalize(ctx)
end

return M
