local function run()
    local workflow = require('core.workflow')
    local root = vim.fn.tempname() .. ' project layers'
    vim.fn.mkdir(root .. '/.nvim', 'p')
    vim.fn.writefile({ 'int main() { return 0; }' }, root .. '/main.cpp')
    vim.fn.writefile({ 'fn main() {}' }, root .. '/main.rs')
    local previous = vim.api.nvim_get_current_buf()
    local files = {}
    for _, extension in ipairs({ 'cpp', 'rs' }) do
        local buf = vim.fn.bufadd(root .. '/main.' .. extension)
        vim.fn.bufload(buf)
        files[#files + 1] = buf
    end
    local commands = require('builders.commands')
    local original, calls = commands.run_task, 0
    commands.run_task = function()
        calls = calls + 1
    end
    local function configure(profile, builder)
        vim.fn.writefile({
            vim.json.encode({
                workflow = profile,
                builder = builder,
                tasks = { run = { argv = { 'not-executed' } }, build = { argv = { 'not-executed' } } },
            }),
        }, root .. '/.nvim/project.json')
    end
    for _, builder in ipairs({ 'cmake', 'cargo', 'commands' }) do
        for _, buf in ipairs(files) do
            vim.api.nvim_set_current_buf(buf)
            configure('kernel', builder)
            local ctx = workflow.context()
            assert(ctx.root == root and ctx.builder_name == builder and ctx.workflow == 'kernel')
            local before = calls
            workflow.execute('run')
            workflow.execute('test')
            workflow.execute('debug')
            assert(calls == before, 'External policy depends on language/backend or was bypassed')
            workflow.execute('build')
            assert(calls == before + 1, 'Kernel build was incorrectly blocked')
            configure('engine', builder)
            workflow.execute('run')
            assert(calls == before + 2, 'Engine action failed to compose with backend')
        end
    end
    commands.run_task = original
    commands.run_task(workflow.context(), {
        argv = { 'python3', '-c', 'import sys; print("main.cpp:1:1: error: probe"); sys.exit(1)' },
        errorformat = '%f:%l:%c: %t%*[^:]: %m',
    })
    assert(
        vim.wait(10000, function()
            return not require('core.tasks').active
        end, 20),
        'Custom task timed out'
    )
    local items = vim.tbl_filter(function(item)
        return item.valid == 1
    end, vim.fn.getqflist())
    assert(
        #items == 1 and vim.api.nvim_buf_get_name(items[1].bufnr) == root .. '/main.cpp',
        'Custom-task diagnostics were not resolved relative to the task root'
    )
    vim.cmd.cclose()
    vim.api.nvim_set_current_buf(previous)
    for _, buf in ipairs(files) do
        vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.fn.delete(root, 'rf')
    print('PASS language-independent engine/kernel workflows across C++, Rust and three backends')
    print('PASS shared custom-task executor and relative diagnostic paths')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd('cquit 1')
end
