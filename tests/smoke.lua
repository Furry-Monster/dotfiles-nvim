-- Run with an isolated XDG_STATE_HOME (see README). No real project is modified.
if not package.loaded["lazy"] then
    vim.opt.loadplugins = true
    dofile(vim.fn.stdpath("config") .. "/init.lua")
end
local function check()
    local config = vim.fn.stdpath("config")
    for _, file in ipairs(vim.fn.globpath(config, "**/*.lua", false, true)) do
        assert(loadfile(file), "Lua syntax error: " .. file)
    end
    require("lazy").load({ plugins = {
        "nvim-lspconfig", "conform.nvim", "overseer.nvim", "nvim-dap", "lualine.nvim",
        "nvim-tree.lua", "telescope.nvim", "mini.diff", "mini.ai", "mini.surround", "which-key.nvim",
    } })
    local features = require("config.features")
    assert(not features.ai and not features.inline, "AI must be off at startup")
    assert(vim.lsp.config.clangd and vim.lsp.config.rust_analyzer)
    assert(vim.lsp.config.omnisharp == nil or not vim.lsp.is_enabled("omnisharp"))
    assert(require("nvim-tree").config or package.loaded["nvim-tree"])
    local conform = require("conform")
    assert(conform.formatters_by_ft.cpp[1] == "clang_format")
    assert(conform.formatters_by_ft.rust[1] == "rustfmt")
    assert(require("dap").configurations.cs == nil, "Unity debug must not be configured")
    assert(require("dap").configurations.rust[1].type == "lldb")

    local project = require("project.settings")
    assert(not pcall(project.validate, { tasks = { { name = "bad", cmd = "echo unsafe" } } }))
    assert(not pcall(project.validate, { env = { SECRET = 123 } }))
    assert(not pcall(project.validate, { debug = { args = { 42 } } }))
    assert(project.validate({ tasks = { { name = "safe", cmd = { "echo", "hello" } } } }))

    local fixture = "/tmp/opencode/nvim-smoke-" .. vim.uv.os_getpid()
    vim.fn.mkdir(fixture .. "/nested", "p")
    vim.fn.writefile({ "cmake_minimum_required(VERSION 3.20)" }, fixture .. "/CMakeLists.txt")
    vim.fn.writefile({ "int main() {return 0;}" }, fixture .. "/nested/main.cpp")
    vim.cmd.edit(fixture .. "/nested/main.cpp")
    assert(require("project.root").get() == fixture, "root detection")
    assert(vim.wait(10000, function()
        return #vim.lsp.get_clients({ bufnr = 0, name = "clangd" }) == 1
    end, 50), "clangd must attach")
    local buf = vim.api.nvim_get_current_buf()
    local before = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    vim.cmd.write()
    assert(before == table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"), "no format on save")
    require("config.format").run()
    assert(before ~= table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"), "manual C++ formatting")

    features.set("git", true)
    features.off()
    assert(not features.git and vim.g.minidiff_disable, "Git switch")
    assert(require("mini.diff").get_buf_data(buf) == nil, "diff lifecycle must be detached")
    features.set("git", true)
    assert(not vim.g.minidiff_disable, "Git switch can re-enable")

    vim.ui.select = function(_, _, callback) callback(nil, 1) end
    require("config.ai").enable()
    assert(not features.ai, "cancelled consent must stay off")
    vim.ui.select = function(items, _, callback) callback(items[2], 2) end
    require("config.ai").enable()
    assert(features.ai and require("config.ai").allowed(buf), "project consent")
    features.set("inline", true)
    assert(require("config.ai").inline_allowed(buf), "inline consent gate")
    local secret = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(secret, fixture .. "/.env.local")
    assert(require("config.buffer").regular(secret), "sensitive test must use a regular buffer")
    assert(not require("config.ai").inline_allowed(secret), "sensitive files must not attach")
    vim.api.nvim_buf_delete(secret, { force = true })
    features.off()
    assert(not require("config.ai").allowed(buf), "master switch revokes consent")
    assert(vim.fn.maparg("=", "n") == "", "Vim = must not be remapped")
    local large = fixture .. "/large.txt"
    vim.bo.modified = false
    vim.fn.writefile({ string.rep("x", require("config.settings").large_file.bytes + 1) }, large)
    vim.cmd.edit(large)
    assert(vim.b.large_file and not require("config.buffer").regular(0), "large-file degradation")
    assert(not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "large files must not highlight with Treesitter")
    print("PASS: syntax, lazy modules, LSP, format, project schema, feature switches and AI consent")
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end
