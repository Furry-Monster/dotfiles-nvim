local M = { consent = {} }
local features = require("config.features")

function M.allowed(buf)
    local root = require("project.root").get(buf)
    return features.ai and M.consent[root] == true
end

function M.inline_allowed(buf)
    if not features.inline or not M.allowed(buf) or not require("config.buffer").regular(buf) then
        return false
    end
    local name = vim.api.nvim_buf_get_name(buf)
    local base = vim.fs.basename(name)
    return not (base:match("^%.env") or base:match("%.pem$") or base:match("%.key$")
        or base:match("%.p12$") or base:match("%.pfx$") or base:match("%.keystore$")
        or base == "id_rsa" or base == "id_ed25519" or name:find("/%.git/"))
end

function M.enable(callback)
    local root = require("project.root").get()
    if features.ai and M.consent[root] then
        if callback then callback(root) end
        return
    end
    vim.ui.select({ "取消", "允许本会话此项目使用 AI" }, {
        prompt = "AI 可能向外部服务发送代码与工程上下文。确认拥有授权？\n" .. root,
    }, function(_, index)
        if index ~= 2 then return end
        M.consent[root] = true
        features.set("ai", true)
        if callback then callback(root) end
    end)
end

function M.toggle()
    if features.ai then features.set("ai", false) else M.enable() end
end

local function provider_stop()
    if package.loaded["copilot.client"] then
        pcall(function() require("copilot.suggestion").dismiss() end)
        require("copilot.client").teardown()
        M.guard_provider_command()
    end
end

function M.guard_provider_command()
    -- No force-attach, workspace injection or provider-side re-enable bypass.
    vim.api.nvim_create_user_command("Copilot", function(opts)
        if not features.inline or not M.allowed() then
            vim.notify("先使用 :AIInlineToggle 并授权当前项目。", vim.log.levels.WARN)
            return
        end
        local args = vim.split(opts.args, "%s+", { trimempty = true })
        local action = args[1] or "status"
        if action == "auth" then
            local method = ({ signin = "signin", signout = "signout", info = "info" })[args[2] or "signin"]
            if method then
                require("copilot.client").use_client(function() require("copilot.auth")[method]({}) end)
            end
        elseif action == "status" then
            require("copilot.status").status()
        else
            vim.notify("此配置仅开放 :Copilot auth [signin|signout|info] 和 :Copilot status；总开关由 Workbench 管理。")
        end
    end, { nargs = "*", force = true, complete = function() return { "auth", "status" } end })
end

function M.inline_toggle()
    if features.inline then features.set("inline", false) return end
    if not require("config.settings").ai.copilot then
        vim.notify("未选择行内 AI 服务。请在 lua/local.lua 设置 ai.copilot = true，再重启。", vim.log.levels.WARN)
        return
    end
    local server = require("config.settings").ai.copilot_server
    if server == "" or vim.fn.executable(server) == 0 then
        vim.notify("请先手动安装 Copilot 原生语言服务并配置 ai.copilot_server；不会自动下载。", vim.log.levels.WARN)
        return
    end
    M.enable(function()
        features.set("inline", true)
        require("lazy").load({ plugins = { "copilot.lua" } })
        if not require("config.copilot").start() then
            features.set("inline", false)
            vim.notify("行内 AI 未启动；请从已授权工程的普通源码文件启用，敏感文件除外。", vim.log.levels.WARN)
        end
    end)
end

function M.agent()
    local argv = require("config.settings").ai.agent
    if #argv == 0 then
        vim.notify("先在 lua/local.lua 设置 ai.agent argv，例如 { 'codex' }；不会自动安装或选择供应商。", vim.log.levels.WARN)
        return
    end
    M.enable(function(root)
        require("config.terminal").open(argv, "ai", { cwd = root, workspace = true })
    end)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("WorkbenchAI", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "WorkbenchFeatureChanged",
        callback = function(ev)
            if ev.data.feature == "ai" and not features.ai then
                M.consent = {}
                provider_stop()
                require("config.terminal").stop("ai")
            elseif ev.data.feature == "inline" and not features.inline then
                provider_stop()
            end
        end,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(ev)
            if package.loaded["copilot.client"] and not M.allowed(ev.buf) then
                require("copilot.client").buf_detach_if_attached(ev.buf)
            end
        end,
    })
    for _, event in ipairs({ "BlinkCmpMenuOpen", "BlinkCmpMenuClose" }) do
        vim.api.nvim_create_autocmd("User", {
            group = group, pattern = event,
            callback = function() vim.b.copilot_suggestion_hidden = event == "BlinkCmpMenuOpen" end,
        })
    end
    vim.api.nvim_create_user_command("AIEnable", function() M.enable() end, {})
    vim.api.nvim_create_user_command("AIDisable", function()
        features.ai, features.inline = false, false
        vim.api.nvim_exec_autocmds("User", { pattern = "WorkbenchFeatureChanged", data = { feature = "ai", enabled = false } })
        vim.cmd.redrawstatus()
    end, {})
    vim.api.nvim_create_user_command("AIToggle", M.toggle, {})
    vim.api.nvim_create_user_command("AIInlineToggle", M.inline_toggle, {})
    vim.api.nvim_create_user_command("AIAgent", M.agent, {})
    vim.keymap.set("n", "<leader>aa", M.agent, { desc = "AI Agent 工作区" })
    vim.keymap.set("n", "<leader>ai", M.inline_toggle, { desc = "行内 AI 独立开关" })
end

return M
