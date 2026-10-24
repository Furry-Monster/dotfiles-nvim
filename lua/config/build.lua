local running = false

vim.api.nvim_create_user_command("Build", function(opts)
    if running then
        vim.notify("已有构建正在运行", vim.log.levels.WARN)
        return
    end

    -- 在启动时固定路径，避免构建过程中切换目录影响结果。
    local cwd = vim.fn.getcwd()
    local build_dir = vim.fs.normalize(
        vim.fn.fnamemodify(
            opts.args ~= "" and opts.args or "build",
            ":p"
        )
    )

    if vim.fn.isdirectory(build_dir) == 0 then
        vim.notify("构建目录不存在：" .. build_dir, vim.log.levels.ERROR)
        return
    end

    -- 使用 Neovim 自带的 GCC 风格诊断解析规则。
    vim.cmd("compiler gcc")
    local errorformat = vim.bo.errorformat

    running = true
    vim.notify("开始构建：" .. build_dir)

    vim.system({
        "cmake",
        "--build",
        build_dir,
        "--parallel",
        "4",
    }, {
        cwd = cwd,
        text = true,
    }, function(result)
        -- 异步回调中不要直接操作编辑器界面。
        vim.schedule(function()
            running = false

            local output = (result.stdout or "")
                .. "\n"
                .. (result.stderr or "")

            vim.fn.setqflist({}, " ", {
                title = "CMake: " .. build_dir,
                lines = vim.split(output, "\n", { plain = true }),
                efm = errorformat,
            })

            if result.code == 0 then
                vim.notify("构建成功")
            else
                vim.notify(
                    "构建失败，退出码：" .. result.code,
                    vim.log.levels.ERROR
                )
                vim.cmd("copen")
            end
        end)
    end)
end, {
    nargs = "?",
    complete = "dir",
    desc = "异步构建 CMake 项目",
})
