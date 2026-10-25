local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.termguicolors = true
opt.cursorline = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.scrolloff = 6
opt.updatetime = 250
opt.timeoutlen = 1000
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.wrap = false
opt.undofile = true
opt.confirm = true
opt.mouse = 'a'
opt.laststatus = 3
opt.statusline = '%f %h%m%r%=%{&filetype}  %l:%c  %p%% '

-- A Windows shell must use its matching command flags. Leave cmd.exe intact
-- on Windows; Bash and PowerShell scripts are launched with argument arrays.
vim.filetype.add({
    extension = {
        vert = 'glsl',
        frag = 'glsl',
        comp = 'glsl',
        geom = 'glsl',
        tesc = 'glsl',
        tese = 'glsl',
        glsl = 'glsl',
        rgen = 'glsl',
        rmiss = 'glsl',
        rchit = 'glsl',
        rahit = 'glsl',
        rint = 'glsl',
        rcall = 'glsl',
        ps1 = 'ps1',
        psm1 = 'ps1',
        psd1 = 'ps1',
    },
})

vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.hl.on_yank()
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'sh', 'cmake', 'json', 'jsonc', 'yaml' },
    callback = function()
        vim.bo.shiftwidth = 2
        vim.bo.tabstop = 2
    end,
})
