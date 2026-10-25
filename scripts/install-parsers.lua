-- nvim --headless -l scripts/install-parsers.lua
if not package.loaded["lazy"] then
    vim.opt.loadplugins = true
    dofile(vim.fn.stdpath("config") .. "/init.lua")
end
require("nvim-treesitter").install({
    "c", "cpp", "rust", "c_sharp", "lua", "luadoc", "vim", "vimdoc", "query",
    "cmake", "bash", "json", "yaml", "toml", "xml", "markdown", "markdown_inline",
    "glsl", "hlsl", "typescript", "tsx", "javascript",
}):wait(600000)
