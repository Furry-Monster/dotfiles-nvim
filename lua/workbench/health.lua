local M = {}

local function tool(name, source, required)
    local path = vim.fn.exepath(name)
    if path == "" then
        local message = name .. " 未安装（来源: " .. source .. "）"
        if required then vim.health.error(message) else vim.health.warn(message) end
    else
        vim.health.ok(name .. ": " .. path .. "（来源: " .. source .. "）")
    end
end

function M.check()
    require("lazy").load({ plugins = { "mason.nvim" } })
    vim.health.start("Workbench 基础")
    if vim.fn.has("nvim-0.12") == 1 then vim.health.ok("Neovim >= 0.12") else vim.health.error("需要 Neovim >= 0.12") end
    for _, name in ipairs({ "git", "rg", "cc", "curl", "tar", "tree-sitter" }) do tool(name, "系统", true) end
    tool("wl-copy", "系统 / Wayland clipboard", false)
    vim.health.info("Konsole 请手动选择 Nerd Font；格式化备用键 <leader>cf；= 始终只负责 Vim 缩进。")

    vim.health.start("主力语言")
    local settings = require("config.settings")
    for _, name in ipairs({ settings.clangd, settings.clang_format, "cmake", "ninja", settings.lldb_dap, "dotnet" }) do
        tool(name, "系统", false)
    end
    for _, name in ipairs({ "cargo", "rustc", "rustfmt", "rust-analyzer" }) do tool(name, "rustup", false) end
    if vim.fn.executable("rust-analyzer") == 1 then
        local result = vim.system({ "rust-analyzer", "--version" }, { text = true }):wait(5000)
        if result.code == 0 then vim.health.ok(vim.trim(result.stdout or "")) else
            vim.health.warn("rustup shim 存在但当前 toolchain 缺少 rust-analyzer；执行 rustup component add rust-analyzer rust-src clippy")
        end
    end
    tool("roslyn-language-server", "Mason: roslyn（扩展源，非 nightly 包）", false)
    tool(settings.dotnet_host, "Roslyn 专属 .NET host；不影响系统 dotnet", false)
    if vim.fn.executable(settings.dotnet_host) == 1 then
        local result = vim.system({ settings.dotnet_host, "--list-runtimes" }, { text = true }):wait(5000)
        if (result.stdout or ""):match("Microsoft.NETCore.App 10%.") then
            vim.health.ok("Roslyn .NET 10 runtime 可用")
        else
            vim.health.warn("Roslyn 需要 .NET 10；请手动安装 SDK，或在本机设置中指定 dotnet_host。配置不会自动安装。")
        end
    end
    tool("neocmakelsp", "Mason（预编译包）", false)
    tool("glsl_analyzer", "Mason", false)
    tool("glslangValidator", "系统 / Vulkan 工具链", false)

    vim.health.start("工具来源冲突")
    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"
    for _, name in ipairs({ "clangd", "clang-format", "rust-analyzer", "rustfmt", "lldb-dap" }) do
        if vim.uv.fs_stat(mason_bin .. name) then
            vim.health.warn(name .. " 出现 Mason 副本；本配置约定由系统/rustup 管理，请移除重复安装。")
        end
    end
    vim.health.info("Mason PATH=append；项目 Prettier 使用 node_modules/.bin；不会自动 npm/pip 全局安装。")

    vim.health.start("隐私与可选功能")
    local features = require("config.features")
    vim.health.ok("AI 总开关: " .. tostring(features.ai) .. "；行内 AI: " .. tostring(features.inline))
    vim.health.ok("Git 总开关: " .. tostring(features.git))
    vim.health.info("状态栏 Quiet 按钮 / :IntegrationsOff / <leader>uQ 可关闭所有受管理 AI 与 Git 功能。")
    if #settings.ai.agent > 0 then tool(settings.ai.agent[1], "用户自行安装的 Agent CLI", false) else
        vim.health.info("尚未选择 AI Agent；见 examples/local.lua。")
    end
    vim.health.info(".nvim.json 仅 :ProjectTrust 显式加载；本机配置 lua/local.lua 不进入 Git。")
end

return M
