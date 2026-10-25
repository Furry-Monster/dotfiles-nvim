-- Explicit bootstrap, not run at editor startup. Never installs system packages.
-- nvim --headless -l scripts/install-tools.lua
if not package.loaded["lazy"] then
    vim.opt.loadplugins = true
    dofile(vim.fn.stdpath("config") .. "/init.lua")
end
require("lazy").load({ plugins = { "mason.nvim" } })
local registry = require("mason-registry")
local names = {
    "lua-language-server", "stylua", "roslyn", "bash-language-server",
    "shfmt", "json-lsp", "yaml-language-server", "taplo", "neocmakelsp",
    "glsl_analyzer", "typescript-language-server",
}
local refreshed, refresh_ok = false, false
registry.refresh(function(ok) refresh_ok, refreshed = ok, true end)
assert(vim.wait(120000, function() return refreshed end, 100), "Mason registry refresh timed out")
assert(refresh_ok, "Mason registry refresh failed")
local packages = {}
for _, name in ipairs(names) do
    assert(registry.has_package(name), "Mason package not found: " .. name)
    local package = registry.get_package(name)
    table.insert(packages, package)
    if not package:is_installed() then package:install() end
end
assert(vim.wait(600000, function()
    return vim.iter(packages):all(function(p) return not p:is_installing() end)
end, 200), "Tool installation timed out; inspect :MasonLog")
local failed = {}
for _, package in ipairs(packages) do
    if package:is_installed() then print("OK " .. package.name) else table.insert(failed, package.name) end
end
assert(#failed == 0, "Failed tools: " .. table.concat(failed, ", ") .. "; inspect :MasonLog")
