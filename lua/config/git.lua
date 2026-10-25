local M = { jobs = {}, views = {}, generation = 0 }
local features = require("config.features")

local function allowed()
    if features.git then return true end
    vim.notify("Git 集成已关闭，使用状态栏 Git 按钮或 :GitEnable 开启。", vim.log.levels.WARN)
    return false
end

function M.show(action)
    if not allowed() then return end
    local root = require("project.root").get()
    local file = vim.api.nvim_buf_get_name(0)
    local args = {
        status = { "status", "--short", "--branch" },
        log = { "log", "-30", "--oneline", "--decorate" },
        diff = { "diff", "--no-ext-diff", "--no-textconv" },
        staged = { "diff", "--cached", "--no-ext-diff", "--no-textconv" },
        blame = { "blame", "-L", vim.fn.line(".") .. ",+1", "--", file },
    }
    if not args[action] then return end
    local generation = M.generation
    local argv = { "git", "--no-pager", "-c", "color.ui=false" }
    vim.list_extend(argv, args[action])
    local job
    job = vim.system(argv, { cwd = root, text = true }, function(result)
        vim.schedule(function()
            M.jobs[job] = nil
            if generation ~= M.generation or not features.git then return end
            if result.code ~= 0 then vim.notify(result.stderr or "Git 失败", vim.log.levels.ERROR) return end
            vim.cmd("botright 15new")
            local buf = vim.api.nvim_get_current_buf()
            M.views[buf] = true
            vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "nofile", "wipe", false
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout or "", "\n", { plain = true }))
            vim.bo[buf].filetype = (action == "diff" or action == "staged") and "diff" or "git"
            vim.bo[buf].modifiable = false
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "关闭 Git 视图" })
        end)
    end)
    M.jobs[job] = true
end

function M.reconcile()
    vim.g.minidiff_disable = not features.git
    local diff = require("mini.diff")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if features.git and require("config.buffer").regular(buf) then
            diff.enable(buf)
        elseif not features.git then
            diff.disable(buf)
        end
    end
    if not features.git then
        M.generation = M.generation + 1
        for job in pairs(M.jobs) do pcall(job.kill, job, 15) end
        M.jobs = {}
        for buf in pairs(M.views) do
            if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
        end
        M.views = {}
        require("config.terminal").stop("git")
    end
end

function M.setup()
    local diff = require("mini.diff")
    local source = diff.gen_source.git()
    local attach = source.attach
    source.attach = function(buf)
        if not features.git or not require("config.buffer").regular(buf) then return false end
        return attach(buf)
    end
    diff.setup({
        source = source,
        view = { style = "sign", signs = { add = "▎", change = "▎", delete = "▁" } },
        mappings = { apply = "", reset = "", textobject = "", goto_first = "", goto_prev = "", goto_next = "", goto_last = "" },
    })
    local function map(lhs, fn, desc)
        vim.keymap.set("n", lhs, function() if allowed() then fn() end end, { desc = desc })
    end
    map("]h", function() diff.goto_hunk("next") end, "下一个 Git hunk")
    map("[h", function() diff.goto_hunk("prev") end, "上一个 Git hunk")
    map("<leader>gp", function() diff.toggle_overlay() end, "Git 行内差异预览")
    map("<leader>gs", function() M.show("status") end, "Git 状态")
    map("<leader>gd", function() M.show("diff") end, "Git 未暂存差异")
    map("<leader>gD", function() M.show("staged") end, "Git 已暂存差异")
    map("<leader>gl", function() M.show("log") end, "Git 提交记录")
    map("<leader>gb", function() M.show("blame") end, "Git 当前行归属")
    map("<leader>gh", function()
        local data = diff.get_buf_data(0)
        local row = vim.fn.line(".")
        for _, hunk in ipairs(data and data.hunks or {}) do
            if row >= math.max(1, hunk.buf_start) and row <= math.max(1, hunk.buf_start + hunk.buf_count - 1) then
                diff.do_hunks(0, "apply", { line_start = math.max(1, hunk.buf_start), line_end = math.max(1, hunk.buf_start + hunk.buf_count - 1) })
                return
            end
        end
    end, "暂存当前 Git hunk（取消暂存用 Git CLI）")
    vim.api.nvim_create_user_command("Git", function(opts)
        if opts.args == "ui" then
            if allowed() then require("config.terminal").open({ "lazygit" }, "git") end
        else M.show(opts.args == "" and "status" or opts.args) end
    end, { nargs = "?", complete = function() return { "status", "diff", "staged", "log", "blame", "ui" } end })
    vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("WorkbenchGit", { clear = true }),
        pattern = "WorkbenchFeatureChanged",
        callback = function(ev)
            if ev.data.feature == "git" then M.reconcile() end
        end,
    })
    M.reconcile()
end

return M
