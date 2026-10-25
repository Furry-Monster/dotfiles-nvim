local M = { args = {} }

local function input(prompt, default, completion)
    local ok, value = pcall(vim.fn.input, { prompt = prompt, default = default or "", completion = completion })
    return ok and value ~= "" and value or nil
end

function M.arguments()
    local root = require("project.root").get()
    local value = input("程序参数 JSON argv: ", vim.json.encode(M.args[root] or {}))
    if not value then return end
    local ok, parsed = pcall(function()
        return require("project.settings").validate({ debug = { args = vim.json.decode(value) } }).debug.args
    end)
    if ok then M.args[root] = parsed else vim.notify(tostring(parsed), vim.log.levels.ERROR) end
end

function M.conditional()
    local value = input("断点条件: ")
    if value then require("dap").set_breakpoint(value) end
end

function M.logpoint()
    local value = input("日志内容（表达式用 {expr}）: ")
    if value then require("dap").set_breakpoint(nil, nil, value) end
end

function M.setup()
    local dap, ui = require("dap"), require("dapui")
    dap.adapters.lldb = function(callback)
        local executable = require("config.settings").lldb_dap
        if vim.fn.executable(executable) == 0 then
            vim.notify("找不到 lldb-dap，请安装系统 LLDB 或配置本机路径。", vim.log.levels.ERROR)
            callback(nil)
            return
        end
        callback({ type = "executable", command = executable, name = "LLDB" })
    end
    local function configuration(rust)
        return {
            name = rust and "Rust: Launch (LLDB)" or "Native: Launch (LLDB)",
            type = "lldb",
            request = "launch",
            program = function()
                local root = require("project.root").get()
                local settings = require("project.settings").get(root)
                local debug = settings.debug or {}
                local default = debug.program or (rust and "target/debug/" or ((settings.build_dir or "build/debug") .. "/"))
                local path = input("可执行文件（留空取消）: ", require("project.settings").path(root, default), "file")
                if not path then return dap.ABORT end
                return require("project.settings").path(root, path)
            end,
            cwd = function()
                local root = require("project.root").get()
                return require("project.settings").path(root, (require("project.settings").get(root).debug or {}).cwd)
            end,
            args = function()
                local root = require("project.root").get()
                return M.args[root] or (require("project.settings").get(root).debug or {}).args or {}
            end,
            env = function() return require("project.settings").get().env or {} end,
            stopOnEntry = false,
            initCommands = function()
                if not rust then return {} end
                local root = require("project.root").get()
                local result = vim.system({ "rustc", "--print", "sysroot" }, {
                    cwd = root, text = true, env = require("project.settings").get(root).env,
                }):wait(5000)
                if result.code ~= 0 then return {} end
                local dir = vim.trim(result.stdout) .. "/lib/rustlib/etc/"
                local commands = {}
                for _, pair in ipairs({ { "command script import", "lldb_lookup.py" }, { "command source", "lldb_commands" } }) do
                    if vim.uv.fs_stat(dir .. pair[2]) then
                        table.insert(commands, pair[1] .. ' "' .. (dir .. pair[2]):gsub('"', '\\"') .. '"')
                    end
                end
                return commands
            end,
        }
    end
    local attach = {
        name = "Native: Attach local process", type = "lldb", request = "attach",
        pid = function() return require("dap.utils").pick_process() end,
        cwd = function() return require("project.root").get() end,
    }
    dap.configurations.cpp = { configuration(false), attach }
    dap.configurations.c = dap.configurations.cpp
    dap.configurations.rust = { configuration(true), vim.deepcopy(attach) }
    ui.setup({
        layouts = {
            { elements = { "scopes", "watches", "stacks", "breakpoints" }, size = 42, position = "left" },
            { elements = { "repl", "console" }, size = 12, position = "bottom" },
        },
    })
    dap.listeners.after.event_initialized.workbench = function() ui.open() end
    -- Keep values and the console visible after exit; close explicitly with <leader>du.
    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
    vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })
end

return M
