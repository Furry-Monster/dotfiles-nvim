-- Neovim 0.12 stable or newer. No project-local Lua is executed automatically.
if vim.fn.has("nvim-0.12") == 0 then
    error("此配置要求 Neovim >= 0.12，请先升级稳定版。")
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
require("config.options")
require("config.autocmds")
require("config.features").setup()
require("config.keymaps")
require("config.lazy")
require("project.settings").setup()
require("config.ai").setup()
