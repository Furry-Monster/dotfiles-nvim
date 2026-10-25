local M = {}
function M.setup()
    vim.lsp.enable("roslyn", false)
    vim.lsp.config("roslyn", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = {
            ["csharp|background_analysis"] = {
                dotnet_analyzer_diagnostics_scope = "openFiles",
                dotnet_compiler_diagnostics_scope = "openFiles",
            },
            ["csharp|code_lens"] = {
                dotnet_enable_references_code_lens = false,
                dotnet_enable_tests_code_lens = false,
            },
            ["csharp|formatting"] = { dotnet_organize_imports_on_format = false },
        },
    })
    local server = require("roslyn.utils").get_roslyn_lsp_path()
    if vim.fn.executable(server) == 0 then
        vim.lsp.enable("roslyn", false)
        vim.notify("C#: 请用 :MasonInstall roslyn 安装 Roslyn；随后 :LspRestart 或重启 Neovim。", vim.log.levels.WARN)
        return
    end
    local host = require("config.settings").dotnet_host
    if vim.fn.executable(host) == 0 then
        vim.notify("找不到 .NET host；请手动安装 SDK 或设置本机 dotnet_host。", vim.log.levels.WARN)
        return
    end
    local runtime = vim.system({ host, "--list-runtimes" }, { text = true }):wait(5000)
    if runtime.code ~= 0 or not (runtime.stdout or ""):match("Microsoft.NETCore.App 10%.") then
        vim.notify("Roslyn 需要 .NET 10。请手动安装相应 SDK 后重启，或在 lua/local.lua 指定 dotnet_host；当前跳过 C# 服务。", vim.log.levels.WARN)
        return
    end
    -- Dedicated stdio process; closing Neovim should not leave a Roslyn daemon.
    local dll = vim.fn.resolve(server):gsub("/roslyn%-language%-server$", "/roslyn-language-server.dll")
    vim.lsp.config("roslyn", {
        cmd = { host, dll, "--stdio" },
        cmd_env = host ~= "dotnet" and { DOTNET_ROOT = vim.fs.dirname(vim.fn.resolve(vim.fn.exepath(host))) } or nil,
    })
    require("roslyn").setup({ broad_search = false, filewatching = "auto" })
    local root_dir = vim.lsp.config.roslyn.root_dir
    vim.lsp.config("roslyn", { root_dir = function(buf, on_dir)
        if require("config.buffer").regular(buf) then root_dir(buf, on_dir) end
    end })
    -- Source upstream handlers only after overriding the initial server command.
    vim.g.loaded_roslyn_plugin = nil
    vim.cmd("runtime plugin/roslyn.lua")
end
return M
