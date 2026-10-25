local M = {
    default_builder = false,
    external_handler = 'Unity Editor',
    external = {
        build = true,
        check = true,
        lint = true,
        configure = true,
        test = true,
        run = true,
        debug = true,
        stop = true,
    },
}

function M.detect(bufnr)
    return vim.fs.root(bufnr, function(name, parent)
        return name == 'ProjectSettings'
            and vim.fn.filereadable(parent .. '/ProjectSettings/ProjectVersion.txt') == 1
            and vim.fn.isdirectory(parent .. '/Assets') == 1
    end)
end

return M
