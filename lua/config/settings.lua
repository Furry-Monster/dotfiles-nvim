-- Copy examples/local.lua to lua/local.lua for machine-specific overrides.
local defaults = {
    icons = true,
    large_file = { bytes = 1024 * 1024, lines = 20000 },
    clangd = "clangd",
    clang_format = "clang-format",
    lldb_dap = "lldb-dap",
    -- User-managed SDK. Override with an absolute path for a separate C# host.
    dotnet_host = "dotnet",
    -- Explicit allowlist only; never use '*' for cross-compilers.
    query_drivers = {},
    ai = {
        agent = {}, -- argv, e.g. { "codex" }; no implicit shell expansion
        copilot = false, -- install/enable the optional inline provider explicitly
        copilot_server = "", -- user-installed native server; never auto-download it
    },
}

local path = vim.fn.stdpath("config") .. "/lua/local.lua"
if vim.uv.fs_stat(path) then
    local ok, overrides = pcall(dofile, path)
    if ok and type(overrides) == "table" then
        defaults = vim.tbl_deep_extend("force", defaults, overrides)
    else
        vim.schedule(function()
            vim.notify("本机配置加载失败: " .. tostring(overrides), vim.log.levels.ERROR)
        end)
    end
end
return defaults
