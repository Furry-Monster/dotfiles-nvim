-- Compatibility with the former builder-local project model.
local cargo = require('projects.cargo')
return {
    path = cargo.path,
    root = cargo.root,
    load = function(root)
        return cargo.options(require('core.context').resolve(root))
    end,
    args = function(root, ...)
        return cargo.args(cargo.options(require('core.context').resolve(root)), ...)
    end,
}
