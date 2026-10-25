local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"
opt.laststatus = 3
opt.showmode = false
opt.cmdheight = 1
opt.scrolloff = 6
opt.sidescrolloff = 6
opt.wrap = false
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.updatetime = 300
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.breakindent = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars:append({ eob = " " })
opt.confirm = true
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = true
opt.backup = false
opt.autowrite = false
opt.exrc = false
opt.modeline = false
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "indent"
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"
opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    severity_sort = true,
    update_in_insert = false,
    underline = true,
    float = { border = "rounded", source = true },
    signs = { text = { [1] = "E", [2] = "W", [3] = "I", [4] = "H" } },
})
