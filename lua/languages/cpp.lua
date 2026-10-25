local M = {}
function M.setup()
    local lsp = require("config.lsp")
    local settings = require("config.settings")
    local cmd = { settings.clangd, "--background-index", "--clang-tidy", "--header-insertion=never" }
    if #settings.query_drivers > 0 then
        table.insert(cmd, "--query-driver=" .. table.concat(settings.query_drivers, ","))
    end
    vim.lsp.config("clangd", {
        cmd = lsp.command(cmd, function(argv, project, root)
            if project.build_dir then
                table.insert(argv, "--compile-commands-dir=" .. require("project.settings").path(root, project.build_dir))
            end
            vim.list_extend(argv, project.clangd_args or {})
        end),
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        before_init = function(params)
            -- clangd >= 22 prefers the standard LSP positionEncodings capability.
            params.capabilities.offsetEncoding = nil
        end,
        root_dir = lsp.root({ ".nvim.json", ".clangd", "compile_commands.json", ".git", "CMakeLists.txt" }),
    })
    if vim.fn.executable(settings.clangd) == 1 then vim.lsp.enable("clangd") end
end
return M
