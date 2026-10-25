local M = {}
function M.setup()
    local base_root = vim.lsp.config.rust_analyzer.root_dir
    local base_before_init = vim.lsp.config.rust_analyzer.before_init
    vim.lsp.config("rust_analyzer", {
        cmd = require("config.lsp").command({ "rust-analyzer" }),
        root_dir = function(buf, on_dir)
            if require("config.buffer").regular(buf) then base_root(buf, on_dir) end
        end,
        before_init = function(params, config)
            local rust = require("project.settings").get(config.root_dir).rust or {}
            local cargo = config.settings["rust-analyzer"].cargo
            cargo.target = rust.target
            cargo.features = rust.features or {}
            cargo.allFeatures = rust.all_features == true
            if base_before_init then base_before_init(params, config) end
        end,
        settings = {
            ["rust-analyzer"] = {
                check = { command = "check" },
                cargo = { allFeatures = false },
                inlayHints = { bindingModeHints = { enable = false } },
            },
        },
    })
    if vim.fn.executable("rust-analyzer") == 1 then vim.lsp.enable("rust_analyzer") end
end
return M
