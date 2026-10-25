local M = {
    filetypes = { 'cs' },
    tools = { 'dotnet' },
    formatters = { cs = { lsp_format = 'prefer' } },
    treesitter = { 'cs' },
}
local selected = {}

function M.command()
    for _, name in ipairs({ 'Microsoft.CodeAnalysis.LanguageServer', 'roslyn-language-server' }) do
        if vim.fn.executable(name) == 1 then
            return { name, '--stdio' }
        end
    end
end

function M.options(root)
    local project = require('core.project')
    local config_root = project.explicit_root(root) or root
    return ((project.load(config_root).languages or {}).csharp or {}), config_root
end

function M.targets(root)
    local solutions, projects = {}, {}
    for name, kind in vim.fs.dir(root) do
        if kind == 'file' then
            if name:lower():match('%.slnx?$') then
                table.insert(solutions, root .. '/' .. name)
            elseif name:lower():match('%.csproj$') then
                table.insert(projects, root .. '/' .. name)
            end
        end
    end
    table.sort(solutions)
    table.sort(projects)
    return solutions, projects
end

function M.open(client, target)
    local root = client.config.root_dir
    local opts, config_root = M.options(root)
    target = target
        or (opts.solution and require('core.project').path(config_root, opts.solution))
        or selected[root]
    local function solution(path)
        if vim.fn.filereadable(path) ~= 1 then
            return vim.notify('C# solution not found: ' .. path, vim.log.levels.ERROR)
        end
        selected[root] = path
        client:notify('solution/open', { solution = vim.uri_from_fname(path) })
    end
    if target then
        return solution(target)
    end
    local solutions, projects = M.targets(root)
    if #solutions == 1 then
        return solution(solutions[1])
    end
    if #solutions > 1 then
        return vim.ui.select(
            solutions,
            { prompt = 'C# solution', format_item = vim.fs.basename },
            function(choice)
                if choice and not client:is_stopped() then
                    solution(choice)
                end
            end
        )
    end
    if #projects > 0 then
        client:notify('project/open', { projects = vim.tbl_map(vim.uri_from_fname, projects) })
    else
        vim.notify('No C# solution/project model found; generate project files with the owning tool')
    end
end

function M.setup_lsp()
    local default_root = vim.lsp.config.roslyn_ls.root_dir
    vim.lsp.config('roslyn_ls', {
        cmd = function(dispatchers, config)
            local options = M.options(config.root_dir)
            local argv = options.cmd or M.command()
            assert(argv and #argv > 0, 'Roslyn language server is not available; see WorkflowHealth')
            return vim.lsp.rpc.start(argv, dispatchers, {
                cwd = config.root_dir,
                env = config.cmd_env,
                detached = config.detached,
            })
        end,
        cmd_env = {
            DOTNET_CLI_TELEMETRY_OPTOUT = '1',
            DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1',
            DOTNET_NOLOGO = '1',
        },
        root_dir = function(bufnr, on_dir)
            local explicit = require('core.project').explicit_root(bufnr)
            local options = explicit and M.options(explicit) or {}
            local function attach(root)
                local opts = M.options(root)
                if opts.cmd or M.command() then
                    on_dir(root)
                else
                    vim.notify_once(
                        'Roslyn is not installed/on PATH; C# LSP is disabled',
                        vim.log.levels.WARN
                    )
                end
            end
            if explicit and options.solution then
                return attach(explicit)
            end
            default_root(bufnr, attach)
        end,
        before_init = function(_, config)
            local opts = M.options(config.root_dir)
            config.settings = vim.tbl_deep_extend('force', config.settings or {}, opts.settings or {})
        end,
        on_init = {
            function(client)
                M.open(client)
            end,
        },
        settings = {
            ['csharp|background_analysis'] = {
                dotnet_analyzer_diagnostics_scope = 'openFiles',
                dotnet_compiler_diagnostics_scope = 'openFiles',
            },
        },
    })
    vim.lsp.enable('roslyn_ls')
    vim.api.nvim_create_user_command('CSharpSolution', function(opts)
        local client = vim.lsp.get_clients({ bufnr = 0, name = 'roslyn_ls' })[1]
        if not client then
            return vim.notify('Roslyn is not attached to this buffer')
        end
        if opts.args ~= '' then
            return M.open(client, require('core.project').path(client.config.root_dir, opts.args))
        end
        local targets = M.targets(client.config.root_dir)
        vim.ui.select(targets, { prompt = 'C# solution', format_item = vim.fs.basename }, function(choice)
            if choice then
                M.open(client, choice)
            end
        end)
    end, { nargs = '?', complete = 'file', desc = 'Select C# analysis solution' })
    vim.api.nvim_create_user_command('CSharpReload', function()
        local clients = vim.lsp.get_clients({ bufnr = 0, name = 'roslyn_ls' })
        if #clients > 0 then
            vim.cmd('lsp restart roslyn_ls')
        else
            vim.lsp.enable('roslyn_ls')
        end
    end, { desc = 'Reload C# project model after regeneration' })
end

function M.check_health()
    local cmd = M.command()
    if cmd then
        vim.health.ok('Roslyn: ' .. vim.fn.exepath(cmd[1]))
    else
        vim.health.warn('Roslyn not found on PATH; see docs/tools.md')
    end
    vim.health.info(
        'C# analysis uses generated .sln/.slnx/.csproj references; no project generation/build command is run here.'
    )
end

return M
