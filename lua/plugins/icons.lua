return {
    {
        'nvim-tree/nvim-web-devicons',
        dependencies = { { 'catppuccin/nvim', name = 'catppuccin' } },
        opts = { default = true, strict = true },
        config = function(_, opts)
            local icons = require('nvim-web-devicons')
            icons.setup(opts)
            local palette = require('catppuccin.palettes').get_palette('mocha')
            local colors = {
                c = 'blue',
                rs = 'peach',
                h = 'blue',
                cpp = 'lavender',
                cc = 'lavender',
                cxx = 'lavender',
                hpp = 'lavender',
                hxx = 'lavender',
                cmake = 'green',
                sh = 'green',
                ps1 = 'mauve',
                psm1 = 'mauve',
                psd1 = 'mauve',
                glsl = 'peach',
                vert = 'peach',
                frag = 'peach',
                comp = 'peach',
                geom = 'peach',
                tesc = 'peach',
                tese = 'peach',
                rgen = 'peach',
                rmiss = 'peach',
                rchit = 'peach',
                rahit = 'peach',
                rint = 'peach',
                rcall = 'peach',
            }
            local overrides = {}
            for extension, color in pairs(colors) do
                local icon = icons.get_icon('file.' .. extension, extension, { default = true })
                overrides[extension] = { icon = icon, color = palette[color], name = 'Workflow' .. extension }
            end
            local cmake_icon = icons.get_icon('CMakeLists.txt', 'txt', { default = true })
            overrides['CMakeLists.txt'] =
                { icon = cmake_icon, color = palette.green, name = 'WorkflowCMakeLists' }
            icons.set_icon(overrides)
        end,
    },
}
