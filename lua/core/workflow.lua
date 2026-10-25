-- Compatibility entry points; new code uses context, actions and config.workflow directly.
return {
    context = function(...)
        return require('core.context').resolve(...)
    end,
    execute = function(...)
        return require('core.actions').execute(...)
    end,
    setup = function()
        return require('config.workflow').setup()
    end,
}
