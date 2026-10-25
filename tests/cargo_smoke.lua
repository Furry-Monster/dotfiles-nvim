-- Uses existing Cargo/rustc only, with an offline dependency-free project in /tmp.
-- Run: nvim --clean -l tests/cargo_smoke.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
assert(vim.fn.executable('cargo') == 1, 'Cargo must already be installed')
local root = vim.fn.tempname() .. ' cargo smoke'
vim.fn.mkdir(root .. '/.nvim', 'p')
vim.fn.mkdir(root .. '/src', 'p')
vim.fn.mkdir(root .. '/assets', 'p')
vim.fn.writefile(
    { '[package]', 'name="nvim_refactor_smoke"', 'version="0.1.0"', 'edition="2021"' },
    root .. '/Cargo.toml'
)
vim.fn.writefile({
    'fn main() { println!("CWD={}", std::env::current_dir().unwrap().display()); println!("ARG={}", std::env::args().nth(1).unwrap()); println!("ENV={}", std::env::var("NVIM_REFACTOR_FIXTURE").unwrap()); }',
}, root .. '/src/main.rs')
vim.fn.writefile({
    vim.json.encode({
        builder = 'cargo',
        build = { env = { CARGO_TARGET_DIR = root .. '/target' } },
        run = { cwd = 'assets', args = { 'hello world' }, env = { NVIM_REFACTOR_FIXTURE = 'yes' } },
    }),
}, root .. '/.nvim/project.json')
local ctx = require('core.context').resolve(root, { filetype = 'rust' })
local cargo = require('builders.cargo')
local completed, artifacts
cargo.start(
    ctx,
    require('projects.cargo').args(require('projects.cargo').options(ctx), 'build', { '--offline' }, true),
    function(ok, built)
        completed, artifacts = ok, built
    end
)
assert(
    vim.wait(30000, function()
        return completed ~= nil
    end, 20),
    'Build timed out'
)
assert(completed and #artifacts == 1, 'Cargo build/artifact parsing failed')
local tasks = require('core.tasks')
local terminal, captured = tasks.terminal
tasks.terminal = function(opts)
    captured = opts
end
cargo.command(ctx, 'run', { '--offline' })
tasks.terminal = terminal
local result = vim.system(captured.argv, { cwd = captured.cwd, env = captured.env, text = true }):wait(15000)
assert(result.code == 0, result.stderr)
assert(result.stdout:find('CWD=' .. root .. '/assets', 1, true), result.stdout)
assert(result.stdout:find('ARG=hello world', 1, true), result.stdout)
assert(result.stdout:find('ENV=yes', 1, true), result.stdout)
local host, sysroot = require('toolchains.rust').info(root)
assert(type(host) == 'string' and type(sysroot) == 'string')
local configs = require('builders.cargo_debug').configurations(ctx)
assert(#configs == 4, 'Expected LLDB/GDB binary/test configurations')
assert(configs[1].cwd == ctx.run.cwd and configs[1].env.NVIM_REFACTOR_FIXTURE == 'yes')
assert(configs[3].type == 'rust_gdb' and configs[3].rustRoot == root)
print('PASS: offline Cargo build, artifacts, run cwd/arguments/env, Rust toolchain and debug configurations')
vim.cmd('qa!')
