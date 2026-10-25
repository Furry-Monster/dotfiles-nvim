local M = {}

function M.start()
    local settings = require("config.settings").ai
    if not settings.copilot or not require("config.ai").inline_allowed(0) then
        require("config.ai").guard_provider_command()
        return false
    end
    if settings.copilot_server == "" or vim.fn.executable(settings.copilot_server) == 0 then
        vim.notify("请手动安装 Copilot 原生语言服务，并在本机设置中填写 ai.copilot_server；不会自动下载。", vim.log.levels.WARN)
        require("config.features").set("inline", false)
        require("config.ai").guard_provider_command()
        return false
    end
    require("copilot").setup({
        server = { type = "binary", custom_server_filepath = settings.copilot_server },
        panel = { enabled = false },
        suggestion = {
            enabled = true,
            auto_trigger = true,
            trigger_on_accept = false,
            hide_during_completion = true,
            keymap = { accept = "<M-l>", next = "<M-]>", prev = "<M-[>", dismiss = "<C-]>" },
        },
        nes = { enabled = false },
        root_dir = function() return require("project.root").get() end,
        should_attach = function(buf) return require("config.ai").inline_allowed(buf) end,
        filetypes = { ["*"] = true },
    })
    if require("copilot.client").is_disabled() then require("copilot.client").setup() end
    require("config.ai").guard_provider_command()
    return true
end

return M
