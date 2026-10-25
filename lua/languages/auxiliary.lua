local M = {}
function M.setup()
    local lsp = require("config.lsp")
    local servers = {
        lua_ls = {
            settings = { Lua = {
                runtime = { version = "LuaJIT" },
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
                hint = { enable = false },
            } },
        },
        bashls = {},
        jsonls = { settings = { json = {
            validate = { enable = true },
            schemas = { {
                fileMatch = { ".nvim.json" },
                url = vim.uri_from_fname(vim.fn.stdpath("config") .. "/examples/nvim.schema.json"),
            } },
        } } },
        yamlls = { settings = { yaml = { keyOrdering = false, schemaStore = { enable = false, url = "" } } } },
        taplo = {},
        neocmake = {},
        ts_ls = {},
        glsl_analyzer = {},
    }
    for name, overrides in pairs(servers) do
        vim.lsp.config(name, overrides)
        local config = vim.lsp.config[name]
        local base_root = config.root_dir
        vim.lsp.config(name, { root_dir = function(buf, on_dir)
            if not require("config.buffer").regular(buf) then return end
            if type(base_root) == "function" then
                base_root(buf, on_dir)
            else
                on_dir(vim.fs.root(buf, config.root_markers or { ".git" }) or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)))
            end
        end })
        if type(config.cmd) == "table" and vim.fn.executable(config.cmd[1]) == 1 then
            vim.lsp.enable(name)
        end
    end
end
return M
