-- Offline Roslyn integration using a Unity-shaped project model, not a real Unity installation.
local function run()
    local root = vim.fn.tempname() .. ' csharp unity'
    local original_cwd = vim.fn.getcwd()
    local environment = {
        DOTNET_CLI_HOME = root .. '/dotnet-home',
        NUGET_PACKAGES = root .. '/nuget-cache',
        DOTNET_CLI_TELEMETRY_OPTOUT = '1',
        DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1',
        DOTNET_NOLOGO = '1',
        DOTNET_CLI_WORKLOAD_UPDATE_NOTIFY_DISABLE = 'true',
        DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false',
        DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = 'false',
    }
    local previous_env = {}
    for name, value in pairs(environment) do
        previous_env[name] = vim.env[name]
        vim.env[name] = value
    end
    local function write(path, lines)
        vim.fn.mkdir(vim.fs.dirname(root .. '/' .. path), 'p')
        vim.fn.writefile(lines, root .. '/' .. path)
    end
    write('ProjectSettings/ProjectVersion.txt', { 'm_EditorVersion: 6000.0.0f1' })
    write('Packages/manifest.json', { '{}' })
    write('NuGet.Config', { '<configuration><packageSources><clear /></packageSources></configuration>' })
    write('References/UnityEngine/UnityEngine.csproj', {
        '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup></Project>',
    })
    write('References/UnityEngine/UnityEngine.cs', {
        'namespace UnityEngine {',
        '    public class MonoBehaviour { public Transform transform { get; } = new Transform(); }',
        '    public class Transform { public string name { get; set; } = ""; }',
        '}',
    })
    write('Assembly-CSharp.csproj', {
        '<Project Sdk="Microsoft.NET.Sdk">',
        '<PropertyGroup><TargetFramework>net10.0</TargetFramework><LangVersion>9.0</LangVersion>',
        '<EnableDefaultCompileItems>false</EnableDefaultCompileItems></PropertyGroup>',
        '<ItemGroup><Compile Include="Assets/**/*.cs" />',
        '<ProjectReference Include="References/UnityEngine/UnityEngine.csproj" /></ItemGroup></Project>',
    })
    write('Game.sln', {
        'Microsoft Visual Studio Solution File, Format Version 12.00',
        '# Visual Studio Version 17',
        'Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "Assembly-CSharp", "Assembly-CSharp.csproj", "{3A051812-71B6-461B-9A7C-421D1ED20F50}"',
        'EndProject',
        'Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "UnityEngine", "References/UnityEngine/UnityEngine.csproj", "{655BD880-E58B-48A5-A331-C34E1CA1D20C}"',
        'EndProject',
        'Global',
        'GlobalSection(SolutionConfigurationPlatforms) = preSolution',
        'Debug|Any CPU = Debug|Any CPU',
        'EndGlobalSection',
        'GlobalSection(ProjectConfigurationPlatforms) = postSolution',
        '{3A051812-71B6-461B-9A7C-421D1ED20F50}.Debug|Any CPU.ActiveCfg = Debug|Any CPU',
        '{3A051812-71B6-461B-9A7C-421D1ED20F50}.Debug|Any CPU.Build.0 = Debug|Any CPU',
        '{655BD880-E58B-48A5-A331-C34E1CA1D20C}.Debug|Any CPU.ActiveCfg = Debug|Any CPU',
        '{655BD880-E58B-48A5-A331-C34E1CA1D20C}.Debug|Any CPU.Build.0 = Debug|Any CPU',
        'EndGlobalSection',
        'EndGlobal',
    })
    write('Assets/Player.cs', {
        'using UnityEngine;',
        'public class Player:MonoBehaviour',
        '{',
        '    public void Awake()',
        '    {',
        '        var item = transform;',
        '        item.name = "Player";',
        '    }',
        '}',
    })
    write('Assets/Native/main.cpp', { 'int main() { return 0; }' })
    write('Assets/Native/CMakeLists.txt', { 'project(probe)' })
    local restore = vim.system(
        { 'dotnet', 'restore', root .. '/Assembly-CSharp.csproj', '--configfile', root .. '/NuGet.Config' },
        { cwd = root, env = environment, text = true }
    ):wait(30000)
    assert(restore.code == 0, restore.stdout .. restore.stderr)
    vim.cmd.cd(root)
    vim.cmd.edit(root .. '/Assets/Player.cs')
    local source_buf = vim.api.nvim_get_current_buf()
    local cpp_buf = vim.fn.bufadd(root .. '/Assets/Native/main.cpp')
    vim.fn.bufload(cpp_buf)
    local workflow = require('core.workflow')
    local tasks, commands, dap = require('core.tasks'), require('builders.commands'), require('dap')
    local start, terminal, custom, debug = tasks.start, tasks.terminal, commands.run_task, dap.continue
    local calls = 0
    local function unexpected()
        calls = calls + 1
    end
    tasks.start, tasks.terminal, commands.run_task, dap.continue =
        unexpected, unexpected, unexpected, unexpected
    for _, buf in ipairs({ source_buf, cpp_buf }) do
        vim.api.nvim_set_current_buf(buf)
        local ctx = workflow.context()
        assert(
            ctx.workflow == 'unity' and ctx.root == root and not ctx.builder,
            'Unity detection leaked into language/build-backend selection'
        )
        for _, action in ipairs({ 'build', 'check', 'lint', 'configure', 'test', 'run', 'debug', 'stop' }) do
            workflow.execute(action)
        end
    end
    tasks.start, tasks.terminal, commands.run_task, dap.continue = start, terminal, custom, debug
    assert(calls == 0, 'Unity editing triggered a task or native debugger')
    print('PASS Unity auto-detection and editor-only policy for C# and C++ sources')
    vim.api.nvim_set_current_buf(source_buf)
    local client
    assert(
        vim.wait(45000, function()
            client = vim.lsp.get_clients({ bufnr = source_buf, name = 'roslyn_ls' })[1]
            return client and client.initialized
        end, 50),
        'Roslyn did not attach'
    )
    local function request(method, params, timeout)
        local response = client:request_sync(method, params, timeout or 5000, source_buf)
        assert(response and not response.err, method .. ': ' .. vim.inspect(response))
        return response.result
    end
    local document = { uri = vim.uri_from_fname(root .. '/Assets/Player.cs') }
    local definition, pending = nil, false
    assert(
        vim.wait(60000, function()
            if definition and vim.inspect(definition):find('UnityEngine.cs', 1, true) then return true end
            if pending then return false end
            pending = true
            client:request('textDocument/definition', {
                textDocument = document,
                position = { line = 1, character = 24 },
            }, function(_, result)
                definition, pending = result, false
            end, source_buf)
            return false
        end, 100),
        'Roslyn did not resolve a referenced source project'
    )
    local hover =
        request('textDocument/hover', { textDocument = document, position = { line = 5, character = 22 } })
    assert(hover and vim.inspect(hover):find('Transform', 1, true), 'Missing inferred property type')
    local completion = request('textDocument/completion', {
        textDocument = document,
        position = { line = 6, character = 13 },
        context = { triggerKind = 2, triggerCharacter = '.' },
    })
    assert(completion and vim.inspect(completion):find('name', 1, true), 'Missing member completion')
    local rename = request('textDocument/rename', {
        textDocument = document,
        position = { line = 1, character = 15 },
        newName = 'RenamedPlayer',
    })
    assert(rename and rename.documentChanges, 'Rename returned no edit')
    vim.lsp.util.apply_workspace_edit(rename, client.offset_encoding)
    assert(
        table.concat(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false), '\n'):find('class RenamedPlayer', 1, true),
        'Rename did not update the declaration'
    )
    local format = request(
        'textDocument/formatting',
        { textDocument = document, options = { tabSize = 4, insertSpaces = true } }
    )
    assert(format and #format > 0, 'Roslyn formatter returned no edits')
    print('PASS Roslyn project references, definition, hover, completion, rename and formatting')
    local solutions = require('languages.csharp').targets(root)
    assert(#solutions == 1 and solutions[1] == root .. '/Game.sln')
    write(
        '.nvim/project.json',
        { vim.json.encode({ workflow = 'unity', languages = { csharp = { solution = 'Game.sln' } } }) }
    )
    local opts, config_root = require('languages.csharp').options(root)
    assert(opts.solution == 'Game.sln' and config_root == root)
    assert(vim.fn.exists(':CSharpSolution') == 2 and vim.fn.exists(':CSharpReload') == 2)
    assert(require('core.format').options().formatters_by_ft.cs.lsp_format == 'prefer')
    assert(vim.treesitter.language.get_lang('cs') == 'c_sharp')
    vim.lsp.enable('roslyn_ls', false)
    vim.cmd.cd(original_cwd)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):find(root, 1, true) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
    for name in pairs(environment) do
        vim.env[name] = previous_env[name]
    end
    vim.fn.delete(root, 'rf')
    print('ALL C# / UNITY INTEGRATION CHECKS PASSED')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd('cquit 1')
end
