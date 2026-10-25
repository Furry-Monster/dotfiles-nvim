-- Copy to lua/local.lua (gitignored). This is trusted machine-local Lua.
return {
    icons = true,
    -- dotnet_host = "/path/to/user-managed/dotnet", -- .NET 10 SDK for Roslyn
    query_drivers = {
        -- "/opt/toolchains/aarch64/bin/aarch64-linux-gnu-g++",
    },
    ai = {
        -- Select one already-installed CLI; the configuration installs none.
        agent = { "codex" },
        -- Optional GitHub Copilot inline suggestions. Requires your own account.
        copilot = false,
        copilot_server = "", -- absolute path to a manually installed native server
    },
}
