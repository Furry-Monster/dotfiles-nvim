local M = {}
local project = require('projects.cargo')

function M.choose_program(ctx, cfg, host, tests)
    local dap = require('dap')
    return coroutine.create(function(co)
        local extra = {}
        if tests then
            table.insert(extra, '--no-run')
        end
        vim.list_extend(extra, cfg.debug.buildArgs or {})
        require('builders.cargo').start(
            ctx,
            project.args(cfg, tests and 'test' or 'build', extra, true, host),
            function(success, artifacts)
                local choices = {}
                for _, artifact in ipairs(artifacts) do
                    if (artifact.test == true) == tests then
                        table.insert(choices, artifact)
                    end
                end
                if not success or #choices == 0 then
                    if success then
                        vim.notify('No executable found; select a bin/example using debug.buildArgs')
                    end
                    coroutine.resume(co, dap.ABORT)
                elseif #choices == 1 then
                    coroutine.resume(co, choices[1].path)
                else
                    vim.ui.select(choices, {
                        prompt = 'Rust executable',
                        format_item = function(item)
                            return item.name .. ' — ' .. item.path
                        end,
                    }, function(choice)
                        coroutine.resume(co, choice and choice.path or dap.ABORT)
                    end)
                end
            end
        )
    end)
end

function M.configurations(ctx)
    local cfg = project.options(ctx)
    local host = require('toolchains.rust').info(ctx.root)
    if cfg.target and cfg.target ~= host then
        return {}
    end
    local configs = {}
    for _, adapter in ipairs({ 'lldb', 'gdb' }) do
        for _, tests in ipairs({ false, true }) do
            table.insert(
                configs,
                require('core.debug').configuration(ctx, adapter, {
                    name = 'Cargo ' .. adapter:upper() .. ': host ' .. (tests and 'tests' or 'binary'),
                    program = function()
                        return M.choose_program(ctx, cfg, host, tests)
                    end,
                })
            )
        end
    end
    return configs
end

return M
