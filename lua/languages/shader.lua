-- Shader source languages share editor integration, not a project/build policy.
local M = {
    filetypes = { 'glsl', 'hlsl', 'shaderslang' },
    tools = {
        'clangd',
        'clang-format',
        'glslangValidator',
        'glslc',
        'spirv-as',
        'spirv-dis',
        'spirv-val',
    },
    formatters = {
        glsl = { 'clang_format' },
        hlsl = { 'clang_format', lsp_format = 'prefer' },
        shaderslang = { lsp_format = 'prefer' },
    },
    treesitter = { 'glsl', 'hlsl', 'shaderslang' },
    servers = {
        shader_clangd = { command = 'clangd', filetypes = { 'glsl', 'hlsl', 'shaderslang' } },
    },
}

function M.setup()
    vim.treesitter.language.register('slang', 'shaderslang')
    vim.filetype.add({
        extension = {
            glsl = 'glsl',
            vert = 'glsl',
            frag = 'glsl',
            comp = 'glsl',
            geom = 'glsl',
            tesc = 'glsl',
            tese = 'glsl',
            rgen = 'glsl',
            rmiss = 'glsl',
            rchit = 'glsl',
            rahit = 'glsl',
            rint = 'glsl',
            rcall = 'glsl',
            hlsl = 'hlsl',
            hlsli = 'hlsl',
            compute = 'hlsl', -- Unity compute source; .shader is ShaderLab, not plain HLSL.
            slang = 'shaderslang',
        },
    })
end

function M.setup_lsp()
    for server, spec in pairs(M.servers) do
        vim.lsp.config(server, {
            cmd = { spec.command, '--background-index', '--completion-style=detailed' },
            filetypes = spec.filetypes,
            root_markers = { '.clangd', 'compile_commands.json', '.git', 'CMakeLists.txt' },
        })
        if vim.fn.executable(spec.command) == 1 then
            vim.lsp.enable(server)
        end
    end
end

function M.check_health()
    vim.health.info('All shader source filetypes connect to shader_clangd via PATH command clangd.')
    vim.health.warn(
        'clangd attachment does not imply GLSL/Slang language support; diagnostics/navigation may be invalid.'
    )
    vim.health.info(
        'Shader targets, defines, include paths and SPIR-V generation belong to the project build.'
    )
    vim.health.info('Tree-sitter parsers: glsl, hlsl, slang (filetype shaderslang).')
end

return M
