-- nvim --headless '+lua dofile("tests/rust.lua")' '+qa!'
-- Offline fixtures only. Does not install components or targets.
local function run()
    local project = require('builders.cargo_project')
    local tasks = require('builders.cargo')
    local root = vim.fn.tempname() .. ' rust workflow'
    local original_cwd, original_cargo_home = vim.fn.getcwd(), vim.env.CARGO_HOME
    local original_offline = vim.env.CARGO_NET_OFFLINE
    local function write(path, lines)
        vim.fn.mkdir(vim.fs.dirname(root .. '/' .. path), 'p')
        vim.fn.writefile(lines, root .. '/' .. path)
    end
    local function configure(data)
        write('.nvim/project.json', {
            vim.json.encode({
                workflow = 'engine',
                builder = 'cargo',
                build = {
                    features = data.features,
                    args = data.cargoArgs,
                    target = data.target,
                    env = data.env,
                },
                languages = { rust = { analyzer = data.analyzer or {} } },
            }),
        })
    end
    vim.env.CARGO_HOME = root .. '/cargo-home'
    vim.env.CARGO_NET_OFFLINE = 'true'
    write('Cargo.toml', { '[workspace]', 'members = ["engine", "support"]', 'resolver = "3"' })
    write('engine/Cargo.toml', {
        '[package]',
        'name = "engine"',
        'version = "0.1.0"',
        'edition = "2024"',
        '[features]',
        'vulkan = []',
    })
    write('support/Cargo.toml', { '[package]', 'name = "support"', 'version = "0.1.0"', 'edition = "2024"' })
    write('support/src/lib.rs', { '#![no_std]', 'pub fn add(a: usize, b: usize) -> usize { a + b }' })
    local source = {
        'macro_rules! answer { () => { 42u32 } }',
        'fn main() {',
        '    let value=answer!();',
        '    println!("{value}");',
        '    let _ = env!("WORKFLOW_TEST");',
        '}',
        '#[test]',
        'fn probe() { assert_eq!(answer!(), 42); }',
    }
    write('engine/src/main.rs', source)
    vim.cmd.cd(root)
    local source_buf = vim.fn.bufadd(root .. '/engine/src/main.rs')
    -- Without editor JSON, nested crates must still resolve to the workspace.
    assert(project.root(source_buf) == root, 'Cargo workspace root discovery failed')
    local cfg = {
        features = { 'vulkan' },
        cargoArgs = { '-p', 'engine', '--offline' },
        env = { WORKFLOW_TEST = 'yes' },
    }
    configure(cfg)
    vim.cmd.edit(root .. '/engine/src/main.rs')
    local function task(command, extra, expected)
        local done, success, artifacts = false
        tasks.start(root, project.args(root, command, extra, true), function(ok, files)
            success, artifacts, done = ok, files, true
        end)
        assert(
            vim.wait(45000, function()
                return done
            end, 25),
            'Cargo task timeout'
        )
        assert(success == expected, 'Unexpected Cargo result: ' .. vim.inspect(vim.fn.getqflist()))
        return artifacts
    end
    local artifacts = task('build', nil, true)
    assert(#artifacts == 1 and artifacts[1].name == 'engine' and not artifacts[1].test)
    print('PASS workspace build and executable artifacts (paths with spaces)')
    local test_artifacts = task('test', { '--no-run' }, true)
    assert(
        vim.iter(test_artifacts):any(function(item)
            return item.test
        end),
        'Missing test executable'
    )
    task('clippy', nil, true)
    print('PASS test artifacts and Clippy')

    write('engine/src/main.rs', { 'fn main() { let _ = missing_name; }' })
    task('check', nil, false)
    local errors = vim.tbl_filter(function(item)
        return item.valid == 1 and item.type == 'E'
    end, vim.fn.getqflist())
    assert(#errors > 0 and errors[1].text:find('E0425', 1, true), 'Missing typed Rust error')
    assert(vim.api.nvim_buf_get_name(errors[1].bufnr) == root .. '/engine/src/main.rs', 'Wrong error path')
    assert(errors[1].lnum == 1 and errors[1].col > 0, 'Wrong error position')
    print('PASS compiler errors into Quickfix with correct path, line, column and code')
    write('engine/src/main.rs', source)
    vim.cmd.cclose()
    vim.api.nvim_set_current_buf(source_buf)
    vim.cmd('edit!')

    assert(
        vim.wait(45000, function()
            local clients = vim.lsp.get_clients({ bufnr = source_buf, name = 'rust_analyzer' })
            return clients[1] and clients[1].initialized
        end, 50),
        'rust-analyzer did not initialize'
    )
    local client = vim.lsp.get_clients({ bufnr = source_buf, name = 'rust_analyzer' })[1]
    local hover
    assert(
        vim.wait(45000, function()
            local response = client:request_sync('textDocument/hover', {
                textDocument = { uri = vim.uri_from_fname(root .. '/engine/src/main.rs') },
                position = { line = 2, character = 9 },
            }, 1500, source_buf)
            hover = response and response.result
            return hover and vim.inspect(hover):find('u32', 1, true)
        end, 100),
        'rust-analyzer did not infer the macro return type'
    )
    assert(client.server_capabilities.semanticTokensProvider, 'Semantic highlighting is unavailable')
    local expansion = client:request_sync('rust-analyzer/expandMacro', {
        textDocument = { uri = vim.uri_from_fname(root .. '/engine/src/main.rs') },
        position = { line = 2, character = 18 },
    }, 5000, source_buf)
    assert(expansion and expansion.result and expansion.result.expansion:find('42', 1, true))
    local formatted = client:request_sync('textDocument/formatting', {
        textDocument = { uri = vim.uri_from_fname(root .. '/engine/src/main.rs') },
        options = { tabSize = 4, insertSpaces = true },
    }, 10000, source_buf)
    assert(formatted and formatted.result and #formatted.result > 0, 'rustfmt returned no edits')
    print('PASS rust-analyzer hover, semantic tokens, macro expansion and rustfmt')

    cfg.features, cfg.cargoArgs = {}, { '-p', 'support', '--offline' }
    cfg.analyzer =
        { cargo = { allTargets = false }, check = { allTargets = false }, cfg = { setTest = false } }
    configure(cfg)
    local settings = require('languages.rust').settings(root)
    assert(
        settings.cargo.allTargets == false
            and settings.check.allTargets == false
            and settings.cfg.setTest == false
    )
    task('check', nil, true)
    vim.api.nvim_set_current_buf(source_buf)
    cfg.target = 'targets/custom.json'
    configure(cfg)
    assert(require('languages.rust').settings(root).cargo.target == root .. '/targets/custom.json')
    local args = project.args(root, 'check')
    assert(vim.tbl_contains(args, root .. '/targets/custom.json'))
    assert(project.path(root, root .. '/absolute.json') == root .. '/absolute.json')
    print('PASS no_std check, explicit analyzer settings and custom-target resolution')

    cfg.target, cfg.analyzer, cfg.cargoArgs, cfg.features =
        nil, {}, { '-p', 'engine', '--offline' }, { 'vulkan' }
    configure(cfg)
    local dap = require('dap')
    for _, adapter in ipairs({ 'lldb', 'rust_gdb' }) do
        vim.api.nvim_set_current_buf(source_buf)
        local configs =
            require('builders.cargo_debug').configurations(require('core.workflow').context(source_buf))
        local config = vim.tbl_filter(function(item)
            return item.type == adapter and item.name:find('binary', 1, true)
        end, configs)[1]
        assert(config, 'Missing Rust DAP configuration')
        config.runInTerminal = false
        config.stopOnEntry, config.stopAtBeginningOfMainSubprogram = true, true
        if adapter == 'lldb' then
            table.insert(config.initCommands, 'settings set target.disable-aslr false')
        end
        dap.run(config)
        assert(
            vim.wait(30000, function()
                local session = dap.session()
                return session and session.current_frame and session.current_frame.scopes
            end, 30),
            adapter .. ' did not populate stack/scopes'
        )
        local done = false
        dap.terminate(nil, nil, function()
            done = true
        end)
        assert(vim.wait(10000, function()
            return done
        end, 30))
        print('PASS native Rust debug build, launch and scopes: ' .. adapter)
    end
    vim.lsp.enable('rust_analyzer', false)
    vim.cmd.cd(original_cwd)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):find(root, 1, true) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
    vim.env.CARGO_HOME, vim.env.CARGO_NET_OFFLINE = original_cargo_home, original_offline
    vim.fn.delete(root, 'rf')
    print('ALL RUST INTEGRATION CHECKS PASSED')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd('cquit 1')
end
