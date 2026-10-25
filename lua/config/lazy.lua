local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path .. "/lua/lazy/init.lua") then
    local result = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", path,
    })
    if vim.v.shell_error ~= 0 then
        error("lazy.nvim 下载失败，请检查网络后重试:\n" .. result)
    end
end
vim.opt.rtp:prepend(path)
require("lazy").setup({
    spec = { { import = "plugins" } },
    defaults = { lazy = true },
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
    checker = { enabled = false },
    change_detection = { enabled = false, notify = false },
    install = { colorscheme = { "tokyonight", "habamax" } },
    ui = { border = "rounded" },
    performance = {
        rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
    },
})
