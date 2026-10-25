local M = { ai = false, inline = false, git = true }
local state_path = vim.fn.stdpath("state") .. "/workbench-features.json"

local function emit(name)
    vim.api.nvim_exec_autocmds("User", {
        pattern = "WorkbenchFeatureChanged",
        data = { feature = name, enabled = M[name] },
    })
    vim.cmd.redrawstatus()
end

function M.set(name, value)
    assert(name == "ai" or name == "git" or name == "inline", "unknown feature")
    value = value == true
    if M[name] == value then
        return
    end
    M[name] = value
    if name == "ai" and not value then
        M.inline = false
    end
    if name == "git" then
        vim.fn.mkdir(vim.fs.dirname(state_path), "p")
        vim.fn.writefile({ vim.json.encode({ git = value }) }, state_path)
    end
    emit(name)
end

function M.off()
    -- Run shutdown hooks even if a provider was manually started out of band.
    M.ai, M.inline = false, false
    emit("ai")
    M.set("git", false)
    vim.notify("安静模式：AI 与 Git 集成已关闭")
end

function M.setup()
    if vim.fn.filereadable(state_path) == 1 then
        local ok, state = pcall(vim.json.decode, table.concat(vim.fn.readfile(state_path), "\n"))
        if ok and type(state) == "table" and type(state.git) == "boolean" then
            M.git = state.git
        end
    end
    vim.g.minidiff_disable = not M.git
    vim.api.nvim_create_user_command("IntegrationsOff", M.off, { desc = "关闭全部 AI/Git 集成" })
    vim.api.nvim_create_user_command("GitToggle", function()
        M.set("git", not M.git)
    end, { desc = "Git 总开关（持久化）" })
    vim.api.nvim_create_user_command("GitDisable", function()
        M.set("git", false)
    end, {})
    vim.api.nvim_create_user_command("GitEnable", function()
        M.set("git", true)
    end, {})
end

return M
