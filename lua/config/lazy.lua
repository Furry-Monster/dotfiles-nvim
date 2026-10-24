local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- 首次启动下载lazynvim
if not vim.uv.fs_stat(lazypath) then
    local output = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })

    if vim.v.shell_error ~= 0 then
        error("下载 lazy.nvim 失败：\n" .. output)
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        { import = "plugins" },
    },
})
