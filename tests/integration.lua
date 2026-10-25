-- Uses real installed tools, but only throw-away projects under /tmp/opencode.
if not package.loaded["lazy"] then
    vim.opt.loadplugins = true
    dofile(vim.fn.stdpath("config") .. "/init.lua")
end

local function check()
    require("lazy").load({ plugins = { "overseer.nvim", "nvim-dap", "mini.diff", "conform.nvim" } })
    local base = "/tmp/opencode/nvim-integration-" .. vim.uv.os_getpid()
    local root = base .. "/cpp project"
    vim.fn.mkdir(root, "p")
    local function write(path, lines)
        vim.fn.mkdir(vim.fs.dirname(path), "p")
        vim.fn.writefile(lines, path)
    end
    local function run(argv, cwd)
        local result = vim.system(argv, { cwd = cwd or root, text = true }):wait(60000)
        assert(result.code == 0, table.concat(argv, " ") .. ": " .. (result.stderr or ""))
        return result.stdout or ""
    end
    local function wait_task(task)
        assert(task, "task was not created")
        assert(vim.wait(60000, function() return task:is_complete() end, 50), "task timeout")
        assert(task.status == "SUCCESS", "task failed: " .. task.name)
    end
    local function client(name, buf)
        assert(vim.wait(60000, function()
            local active = vim.lsp.get_clients({ name = name, bufnr = buf })
            return active[1] and active[1].initialized
        end, 100), name .. " did not initialize")
        return vim.lsp.get_clients({ name = name, bufnr = buf })[1]
    end
    write(root .. "/main.cpp", {
        "int main() {",
        "    int value = 41;",
        "    value += 1;",
        "    return value == 42 ? 0 : 1;",
        "}",
    })
    write(root .. "/CMakeLists.txt", {
        "cmake_minimum_required(VERSION 3.25)", "project(smoke LANGUAGES CXX)",
        "add_executable(smoke main.cpp)", "enable_testing()", "add_test(NAME smoke COMMAND smoke)",
    })
    local presets = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/examples/CMakePresets.json"), "\n"))
    write(root .. "/CMakePresets.json", { vim.json.encode(presets) })
    run({ "git", "init", "-q" })
    run({ "git", "add", "main.cpp", "CMakeLists.txt", "CMakePresets.json" })
    run({ "git", "-c", "user.name=Workbench Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture" })
    vim.cmd.edit(vim.fn.fnameescape(root .. "/main.cpp"))
    local cpp_buf = vim.api.nvim_get_current_buf()
    local settings = require("project.settings")
    assert(vim.tbl_isempty(settings.get(root)), "project config must not auto-load")
    settings.cache[root] = {
        build_dir = "build/linux-debug",
        configure_preset = "linux-debug", build_preset = "linux-debug", test_preset = "linux-debug",
    }
    local tasks = require("config.tasks")
    for _, kind in ipairs({ "configure", "build", "test" }) do
        tasks.cmake(kind)
        wait_task(tasks.last[root])
    end
    assert(vim.uv.fs_stat(root .. "/build/linux-debug/compile_commands.json"), "compile database missing")
    client("clangd", cpp_buf)
    vim.cmd.LspRestart()
    assert(vim.wait(10000, function()
        local active = vim.lsp.get_clients({ name = "clangd", bufnr = cpp_buf })
        return active[1] and active[1].initialized
    end, 100), "clangd restart")
    print("PASS: CMake configure/build/CTest presets, paths with spaces and clangd restart")

    local features = require("config.features")
    features.set("git", true)
    require("config.git").reconcile()
    assert(vim.wait(10000, function()
        local data = require("mini.diff").get_buf_data(cpp_buf)
        return data and data.ref_text ~= nil
    end, 50), "Git source not attached")
    features.set("git", false)
    assert(require("mini.diff").get_buf_data(cpp_buf) == nil, "Git watcher lifecycle")
    require("config.git").show("status")
    assert(next(require("config.git").jobs) == nil, "Git off must block queries")
    features.set("git", true)
    assert(vim.wait(10000, function()
        local data = require("mini.diff").get_buf_data(cpp_buf)
        return data and data.ref_text ~= nil
    end, 50), "Git re-enable must reattach")

    local failed = tasks.run({ "bash", "-c", "printf 'main.cpp:3:5: error: fixture failure\\n'; exit 1" }, { root = root })
    assert(vim.wait(10000, function() return failed:is_complete() end, 50))
    assert(failed.status == "FAILURE")
    local qf = vim.fn.getqflist()
    assert(qf[1] and qf[1].lnum == 3, "quickfix error parsing")
    assert(vim.api.nvim_buf_get_name(qf[1].bufnr) == root .. "/main.cpp", "quickfix relative path")
    vim.cmd.cclose()
    vim.api.nvim_set_current_buf(cpp_buf)
    local cancelled = tasks.run({ "sleep", "30" }, { root = root })
    vim.cmd.TaskStop()
    assert(vim.wait(5000, function() return cancelled:is_complete() end, 50), "task cancellation")
    print("PASS: Git detach/re-enable, task failure quickfix and cancellation")

    local rust = base .. "/rust"
    write(rust .. "/Cargo.toml", {
        '[package]', 'name = "workbench_test"', 'version = "0.1.0"', 'edition = "2024"',
    })
    write(rust .. "/src/main.rs", {
        "fn main() { println!(\"hello\"); }",
        "#[test] fn passes() { assert_eq!(2 + 2, 4); }",
    })
    vim.cmd.edit(rust .. "/src/main.rs")
    local rust_buf = vim.api.nvim_get_current_buf()
    client("rust_analyzer", rust_buf)
    wait_task(tasks.cargo("build"))
    wait_task(tasks.cargo("test"))
    wait_task(tasks.cargo("clippy"))
    local before = vim.api.nvim_buf_get_lines(rust_buf, 0, -1, false)
    require("config.format").run()
    assert(not vim.deep_equal(before, vim.api.nvim_buf_get_lines(rust_buf, 0, -1, false)), "rustfmt manual formatting")
    vim.bo[rust_buf].modified = false
    print("PASS: Rust LSP, Cargo build/test/clippy, rustfmt edition 2024")

    local host = require("config.settings").dotnet_host
    local runtimes = vim.system({ host, "--list-runtimes" }, { text = true }):wait(5000)
    if (runtimes.stdout or ""):match("Microsoft.NETCore.App 10%.") then
    local cs = base .. "/csharp"
    write(cs .. "/Fixture.csproj", {
        '<Project Sdk="Microsoft.NET.Sdk">',
        '  <PropertyGroup><TargetFramework>net8.0</TargetFramework></PropertyGroup>',
        '</Project>',
    })
    write(cs .. "/Fixture.cs", {
        "public class Fixture {",
        "public int Add(int x,int y){return x+y;}",
        "}",
    })
    run({ "dotnet", "restore", "--ignore-failed-sources", cs .. "/Fixture.csproj" }, cs)
    vim.cmd.edit(cs .. "/Fixture.cs")
    local cs_buf = vim.api.nvim_get_current_buf()
    local roslyn = client("roslyn", cs_buf)
    assert(roslyn.config.cmd[#roslyn.config.cmd] == "--stdio", "Roslyn must not daemonize")
    assert(vim.wait(60000, function()
        local result = roslyn:request_sync("textDocument/documentSymbol", {
            textDocument = { uri = vim.uri_from_bufnr(cs_buf) },
        }, 3000, cs_buf)
        return result and result.result and #result.result > 0
    end, 500), "Roslyn must return semantic symbols")
    local cs_before = vim.api.nvim_buf_get_lines(cs_buf, 0, -1, false)
    require("config.format").run()
    assert(not vim.deep_equal(cs_before, vim.api.nvim_buf_get_lines(cs_buf, 0, -1, false)), "C# manual formatting")
    vim.bo[cs_buf].modified = false
    print("PASS: Roslyn real project load, symbols and C# formatting (Unity remains manual acceptance)")
    else
        local cs = base .. "/csharp-unavailable"
        write(cs .. "/Fixture.csproj", { '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net8.0</TargetFramework></PropertyGroup></Project>' })
        write(cs .. "/Fixture.cs", { "public class Fixture {}" })
        vim.cmd.edit(cs .. "/Fixture.cs")
        assert(not vim.lsp.is_enabled("roslyn"), "missing runtime must disable Roslyn cleanly")
        print("SKIP: Roslyn requires user-installed .NET 10 SDK; no SDK was installed by the test")
    end

    vim.api.nvim_set_current_buf(cpp_buf)
    local dap = require("dap")
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    dap.toggle_breakpoint()
    local stopped = false
    dap.listeners.after.event_stopped.integration = function() stopped = true end
    local launch = vim.deepcopy(dap.configurations.cpp[1])
    launch.program = root .. "/build/linux-debug/smoke"
    launch.cwd, launch.args, launch.env = root, {}, {}
    dap.run(launch)
    assert(vim.wait(20000, function() return stopped end, 50), "LLDB launch/breakpoint timeout; inspect :DapShowLog")
    assert(vim.wait(5000, function()
        return dap.session() and dap.session().current_frame and dap.session().stopped_thread_id
    end, 50), "DAP stopped state")
    local evaluated
    dap.session():request("evaluate", {
        expression = "value", frameId = dap.session().current_frame.id, context = "watch",
    }, function(err, response)
        assert(not err, vim.inspect(err))
        evaluated = response.result
    end)
    assert(vim.wait(5000, function() return evaluated ~= nil end, 50), "DAP evaluate timeout")
    assert(evaluated:find("41", 1, true), "DAP local variable value")
    dap.terminate()
    assert(vim.wait(10000, function() return dap.session() == nil end, 50), "DAP termination")
    require("dapui").close()
    print("PASS: real lldb-dap launch, breakpoint and termination")

    vim.api.nvim_set_current_buf(cpp_buf)
    vim.ui.select = function(items, _, callback) callback(items[2], 2) end
    require("config.settings").ai.agent = { "cat" } -- fake agent: no service or network
    require("config.ai").agent()
    local terminal = require("config.terminal")
    assert(next(terminal.sessions), "Agent workspace not created")
    features.off()
    assert(next(terminal.sessions) == nil and not features.ai and not features.inline and not features.git)
    assert(next(require("config.ai").consent) == nil, "AI consent must be revoked")
    print("PASS: managed Agent terminal workspace and all-off shutdown (no AI service contacted)")
    print("Integration fixtures: " .. base)
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    if package.loaded.dap and require("dap").session() then require("dap").terminate() end
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end
