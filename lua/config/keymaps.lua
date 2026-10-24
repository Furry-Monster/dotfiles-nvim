vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymap = vim.keymap.set
-- window nav
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")
-- quick save and exit
keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")
-- 清除搜索highlight
keymap("n", "<leader>nh", ":nohl<CR>")
-- quick fix nav
keymap("n", "]q", "<cmd>cnext<CR>", { desc = "下一个quick fix项" })
keymap("n", "[q", "<cmd>cprevious<CR>", { desc = "上一个 quickfix 项" })
keymap("n", "<leader>co", "<cmd>copen<CR>", { desc = "打开 quickfix" })
keymap("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "关闭 quickfix" })
