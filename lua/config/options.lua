local opt = vim.opt

opt.number = true
opt.relativenumber = true -- 相对行号
opt.signcolumn = "yes"    -- 始终显示 LSP 诊断符号列
opt.cursorline = true
opt.scrolloff = 8         -- 光标上下保留 8 行缓冲
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.updatetime = 250
opt.clipboard = "unnamedplus" -- 系统剪贴板
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"
