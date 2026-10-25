-- Declarative JSON only. Loading requires :ProjectTrust; never run project Lua.
local M = { cache = {} }

function M.get(root)
    return M.cache[M.base(root)] or {}
end

function M.base(root)
    root = root or require("project.root").get()
    if M.cache[root] then return root end
    for parent in vim.fs.parents(root) do
        if M.cache[parent] then return parent end
    end
    return root
end

function M.path(root, path)
    if not path or path == "" then
        return root
    end
    return vim.fs.normalize(path:sub(1, 1) == "/" and path or (root .. "/" .. path))
end

local function string_list(value)
    if type(value) ~= "table" or not vim.islist(value) then
        return false
    end
    for _, v in ipairs(value) do
        if type(v) ~= "string" then
            return false
        end
    end
    return true
end

function M.validate(data)
    assert(type(data) == "table", "根对象必须是 JSON object")
    for _, key in ipairs({ "build_dir", "configure_preset", "build_preset", "test_preset" }) do
        assert(data[key] == nil or type(data[key]) == "string", key .. " 必须是字符串")
    end
    for _, key in ipairs({ "clangd_args", "cargo_args" }) do
        assert(data[key] == nil or string_list(data[key]), key .. " 必须是字符串数组")
    end
    assert(data.rust == nil or type(data.rust) == "table", "rust 必须是对象")
    if data.rust then
        assert(data.rust.target == nil or type(data.rust.target) == "string", "rust.target 必须是字符串")
        assert(data.rust.features == nil or string_list(data.rust.features), "rust.features 必须是字符串数组")
        assert(data.rust.all_features == nil or type(data.rust.all_features) == "boolean", "rust.all_features 必须是布尔值")
    end
    assert(data.env == nil or type(data.env) == "table", "env 必须是对象")
    for k, v in pairs(data.env or {}) do
        assert(type(k) == "string" and type(v) == "string", "env 值必须是字符串")
    end
    assert(data.tasks == nil or (type(data.tasks) == "table" and vim.islist(data.tasks)), "tasks 必须是数组")
    for _, task in ipairs(data.tasks or {}) do
        assert(type(task) == "table" and type(task.name) == "string", "task 缺少 name")
        assert(string_list(task.cmd) and #task.cmd > 0, "task.cmd 必须是非空 argv")
        assert(task.cwd == nil or type(task.cwd) == "string", "task.cwd 必须是字符串")
    end
    local debug = data.debug
    assert(debug == nil or type(debug) == "table", "debug 必须是对象")
    if debug then
        for _, key in ipairs({ "program", "cwd" }) do
            assert(debug[key] == nil or type(debug[key]) == "string", "debug." .. key .. " 必须是字符串")
        end
        assert(debug.args == nil or string_list(debug.args), "debug.args 必须是字符串数组")
    end
    return data
end

function M.setup()
    vim.api.nvim_create_user_command("ProjectTrust", function()
        local root = require("project.root").get()
        local path = root .. "/.nvim.json"
        if vim.fn.filereadable(path) == 0 then
            vim.notify("未找到 " .. path, vim.log.levels.WARN)
            return
        end
        local content = vim.secure.read(path)
        if not content then
            return
        end
        local ok, result = pcall(function()
            return M.validate(vim.json.decode(content))
        end)
        if not ok then
            vim.notify("项目设置无效: " .. tostring(result), vim.log.levels.ERROR)
            return
        end
        M.cache[root] = result
        vim.notify("项目设置已加载；已有 LSP 请用 :LspRestart 更新。每次会话需显式加载。")
    end, { desc = "信任并加载当前工程的声明式 .nvim.json" })
    vim.api.nvim_create_user_command("ProjectForget", function()
        M.cache[require("project.root").get()] = nil
        vim.notify("已移除本会话项目设置；已有 LSP 请重启。永久撤销授权见 :h :trust。")
    end, {})
    vim.api.nvim_create_user_command("ProjectRoot", function()
        vim.notify(require("project.root").get())
    end, {})
end

return M
