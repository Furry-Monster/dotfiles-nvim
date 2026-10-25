local function project_prettier(_, ctx)
    local boundary = vim.fs.root(ctx.buf, { ".git" }) or require("project.root").get(ctx.buf)
    local dir = ctx.dirname
    while dir do
        local path = dir .. "/node_modules/.bin/prettier"
        if vim.fn.executable(path) == 1 then return path end
        if dir == boundary then break end
        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir = parent
    end
    -- A missing absolute path deliberately prevents fallback to a global copy.
    return boundary .. "/node_modules/.bin/prettier"
end

return {
    {
        "stevearc/conform.nvim",
        cmd = { "ConformInfo", "Format" },
        keys = {
            { "<M-S-f>", function() require("config.format").run() end, mode = { "n", "x" }, desc = "手动格式化" },
            { "<leader>cf", function() require("config.format").run() end, mode = { "n", "x" }, desc = "手动格式化" },
        },
        opts = {
            notify_on_error = true,
            formatters_by_ft = {
                c = { "clang_format" }, cpp = { "clang_format" }, objc = { "clang_format" },
                rust = { "rustfmt" }, lua = { "stylua" },
                javascript = { "prettier" }, typescript = { "prettier" },
                javascriptreact = { "prettier" }, typescriptreact = { "prettier" },
                json = { "prettier" }, jsonc = { "prettier" }, yaml = { "prettier" },
                markdown = { "prettier" }, sh = { "shfmt" }, bash = { "shfmt" },
                toml = { "taplo" },
            },
            formatters = {
                clang_format = { command = require("config.settings").clang_format },
                prettier = { command = project_prettier },
            },
        },
        config = function(_, opts)
            require("conform").setup(opts)
            vim.api.nvim_create_user_command("Format", function(args)
                require("config.format").run(args.range > 0 and { args.line1, args.line2 } or nil)
            end, { range = true, desc = "手动格式化文件或行范围" })
        end,
    },
}
