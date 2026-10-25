local M = {}
local markers = {
    ".nvim.json", ".git", "CMakePresets.json", "CMakeLists.txt", "Cargo.toml",
    "ProjectSettings", "package.json", "justfile", "Makefile",
}

function M.get(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or name == "" then
        return vim.b[buf].workbench_root or vim.t.workbench_root or vim.fn.getcwd()
    end
    local root = vim.fs.root(buf, markers) or vim.fs.dirname(name) or vim.fn.getcwd()
    return vim.uv.fs_realpath(root) or vim.fs.normalize(root)
end

return M
