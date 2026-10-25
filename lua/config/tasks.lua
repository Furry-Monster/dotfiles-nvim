local M = { last = {} }
local project = require("project.settings")

local function compiler_errorformat(name)
    local buf = vim.api.nvim_create_buf(false, true)
    local efm
    vim.api.nvim_buf_call(buf, function()
        vim.cmd("compiler " .. name)
        efm = vim.bo.errorformat
    end)
    vim.api.nvim_buf_delete(buf, { force = true })
    return efm
end

function M.run(argv, opts)
    opts = opts or {}
    local root = opts.root or require("project.root").get()
    if vim.fn.executable(argv[1]) == 0 then
        vim.notify("工具未安装: " .. argv[1], vim.log.levels.ERROR)
        return
    end
    local name = opts.name or table.concat(argv, " ")
    for _, task in ipairs(require("overseer").list_tasks()) do
        if task.cwd == (opts.cwd or root) and task.name == name and task:is_running() then
            vim.notify("同一任务已在运行，请先停止或等待完成", vim.log.levels.WARN)
            return
        end
    end
    local efm = compiler_errorformat(opts.compiler or "gcc")
    local task = require("overseer").new_task({
        name = name,
        cmd = argv,
        cwd = opts.cwd or root,
        env = vim.tbl_extend("force", project.get(root).env or {}, opts.env or {}),
        metadata = { workbench_root = root },
        components = {
            { "on_output_quickfix", errorformat = efm, open_on_exit = "failure", items_only = true, tail = true },
            "default",
        },
    })
    M.last[root] = task
    task:start()
    require("overseer").open({ enter = false })
    return task
end

local function build_dir(root)
    return project.path(root, project.get(root).build_dir or "build/debug")
end

-- Ask CMake itself: includes, inheritance, conditions and user presets stay native.
local function preset(root, kind, callback)
    local settings = project.get(root)
    if settings[kind .. "_preset"] then
        callback(settings[kind .. "_preset"])
        return
    end
    if not vim.uv.fs_stat(root .. "/CMakePresets.json") and not vim.uv.fs_stat(root .. "/CMakeUserPresets.json") then
        callback(nil)
        return
    end
    vim.system({ "cmake", "--list-presets=" .. kind }, { cwd = root, text = true, env = settings.env }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                vim.notify(result.stderr or "无法读取 CMake presets", vim.log.levels.ERROR)
                return
            end
            local names = {}
            for line in (result.stdout or ""):gmatch("[^\n]+") do
                local name = line:match('^%s+"([^"]+)"')
                if name then table.insert(names, name) end
            end
            if #names == 0 then
                callback(nil)
            else
                vim.ui.select(names, { prompt = "CMake " .. kind .. " preset" }, function(choice)
                    if choice then callback(choice) end
                end)
            end
        end)
    end)
end

function M.cmake(kind, target)
    local root = require("project.root").get()
    if vim.fn.executable("cmake") == 0 then
        vim.notify("未安装 cmake", vim.log.levels.ERROR)
        return
    end
    preset(root, kind, function(choice)
        local argv
        if kind == "configure" then
            argv = choice and { "cmake", "--preset", choice }
                or { "cmake", "-S", root, "-B", build_dir(root), "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }
            if not choice and not vim.uv.fs_stat(build_dir(root) .. "/CMakeCache.txt") and vim.fn.executable("ninja") == 1 then
                vim.list_extend(argv, { "-G", "Ninja" })
            end
        elseif kind == "build" then
            argv = choice and { "cmake", "--build", "--preset", choice }
                or { "cmake", "--build", build_dir(root) }
            vim.list_extend(argv, { "--parallel" })
            if target then vim.list_extend(argv, { "--target", target }) end
        else
            argv = choice and { "ctest", "--preset", choice, "--output-on-failure" }
                or { "ctest", "--test-dir", build_dir(root), "--output-on-failure" }
        end
        M.run(argv, { root = root })
    end)
end

function M.cargo(action)
    local root = require("project.root").get()
    local argv = { "cargo", action, "--color", "never" }
    vim.list_extend(argv, project.get(root).cargo_args or {})
    return M.run(argv, { root = root, compiler = "rustc" })
end

function M.build()
    local root = require("project.root").get()
    if vim.uv.fs_stat(root .. "/ProjectSettings/ProjectVersion.txt") then
        vim.notify("Unity 构建请在 Unity Editor 中执行；也可显式定义项目任务。")
    elseif vim.fs.find("Cargo.toml", { path = root, upward = true })[1] then
        M.cargo("build")
    elseif vim.uv.fs_stat(root .. "/CMakeLists.txt") or vim.uv.fs_stat(root .. "/CMakePresets.json") then
        M.cmake("build")
    else
        vim.cmd.Task()
    end
end

function M.test()
    local root = require("project.root").get()
    if vim.uv.fs_stat(root .. "/ProjectSettings/ProjectVersion.txt") then
        vim.notify("本配置不集成 Unity 测试。")
    elseif vim.fs.find("Cargo.toml", { path = root, upward = true })[1] then
        M.cargo("test")
    else
        M.cmake("test")
    end
end

function M.setup()
    vim.api.nvim_create_user_command("Build", M.build, {})
    vim.api.nvim_create_user_command("CMakeConfigure", function() M.cmake("configure") end, {})
    vim.api.nvim_create_user_command("CMakeBuild", function() M.cmake("build") end, {})
    vim.api.nvim_create_user_command("CTest", function() M.cmake("test") end, {})
    vim.api.nvim_create_user_command("CMakeTarget", function()
        vim.ui.input({ prompt = "构建 target: " }, function(value)
            if value and value ~= "" then M.cmake("build", value) end
        end)
    end, {})
    vim.api.nvim_create_user_command("BuildDirectory", function(opts)
        local root = require("project.root").get()
        local function apply(value)
            if not value or value == "" then return end
            project.cache[root] = vim.tbl_extend("force", project.get(root), { build_dir = value })
            vim.notify("构建目录: " .. build_dir(root) .. "；clangd 请用 :LspRestart 更新。")
        end
        if opts.args ~= "" then apply(opts.args) else
            vim.ui.input({ prompt = "构建/compile_commands 目录: ", default = build_dir(root), completion = "dir" }, apply)
        end
    end, { nargs = "?", complete = "dir" })
    vim.api.nvim_create_user_command("Cargo", function(opts)
        M.cargo(opts.args == "" and "build" or opts.args)
    end, { nargs = "?", complete = function() return { "build", "check", "test", "clippy", "run" } end })
    vim.api.nvim_create_user_command("CargoArgs", function()
        local root = require("project.root").get()
        vim.ui.input({ prompt = 'Cargo 额外参数（JSON argv）: ', default = vim.json.encode(project.get(root).cargo_args or {}) }, function(value)
            if not value then return end
            local ok, data = pcall(function()
                return project.validate({ cargo_args = vim.json.decode(value) })
            end)
            if not ok then vim.notify(tostring(data), vim.log.levels.ERROR) return end
            project.cache[root] = vim.tbl_extend("force", project.get(root), data)
        end)
    end, {})
    vim.api.nvim_create_user_command("Task", function()
        local root = require("project.root").get()
        local tasks = project.get(root).tasks or {}
        if #tasks == 0 then
            require("overseer").run_task({ cwd = root })
            return
        end
        vim.ui.select(tasks, { prompt = "工程任务", format_item = function(t) return t.name end }, function(task)
            if not task then return end
            M.run(task.cmd, { name = task.name, root = root, cwd = project.path(root, task.cwd) })
        end)
    end, {})
    vim.api.nvim_create_user_command("TaskRepeat", function()
        local task = M.last[require("project.root").get()]
        if not task or task:is_disposed() then
            vim.notify("当前工程没有可重跑的任务", vim.log.levels.WARN)
        elseif task:is_running() then
            vim.notify("任务仍在运行，请先停止", vim.log.levels.WARN)
        else
            task:restart()
        end
    end, {})
    vim.api.nvim_create_user_command("TaskStop", function()
        local root = require("project.root").get()
        for _, task in ipairs(require("overseer").list_tasks()) do
            if task.metadata.workbench_root == root and task:is_running() then task:stop() end
        end
    end, {})
    vim.api.nvim_create_user_command("ShaderCheck", function()
        local file, ft = vim.api.nvim_buf_get_name(0), vim.bo.filetype
        if vim.bo.modified then vim.notify("请先保存 Shader 文件", vim.log.levels.WARN) return end
        if ft == "glsl" then
            M.run({ "glslangValidator", file })
        else
            vim.notify("HLSL/ShaderLab 的 entry、profile、宏依赖工程；请在 .nvim.json 定义 DXC/Unity 验证任务。")
        end
    end, {})
end

return M
