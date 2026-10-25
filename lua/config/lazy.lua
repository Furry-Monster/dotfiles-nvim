local path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(path) then
    local out = vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        'https://github.com/folke/lazy.nvim.git',
        path,
    })
    if vim.v.shell_error ~= 0 then
        error('lazy.nvim installation failed:\n' .. out)
    end
end
vim.opt.rtp:prepend(path)
require('lazy').setup({ { import = 'plugins' } }, {
    local_spec = false,
    checker = { enabled = false },
    change_detection = { notify = false },
    rocks = { enabled = false },
    -- Reuse tools previously installed with Mason without requiring its UI.
    performance = { rtp = { disabled_plugins = { 'tutor' } } },
})
