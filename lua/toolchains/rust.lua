local M = {}

function M.info(root)
    local opts = { cwd = root, text = true, env = { RUSTUP_AUTO_INSTALL = '0' } }
    local result = vim.system({ 'rustc', '-vV' }, opts):wait(3000)
    assert(result.code == 0, 'Cannot query project rustc; check rust-toolchain.toml in tmux')
    local host = result.stdout:match('host: ([^\r\n]+)')
    assert(host, 'rustc did not report its host target')
    local sysroot = vim.system({ 'rustc', '--print', 'sysroot' }, opts):wait(3000)
    return host, sysroot.code == 0 and vim.trim(sysroot.stdout) or nil
end

return M
