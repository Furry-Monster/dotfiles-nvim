local M = {}
-- Explicit, path-based exclusions; no Git process is used for discovery.
local excluded = { ".git", "Library", "Temp", "obj", "target", "node_modules", "build", "Builds" }
local function args(all)
    local result = { "rg", "--files", "--hidden", "--glob", "!.git/**" }
    if all then
        table.insert(result, "--no-ignore")
    else
        for _, dir in ipairs(excluded) do
            vim.list_extend(result, { "--glob", "!**/" .. dir .. "/**" })
        end
    end
    return result
end

function M.files(all)
    require("telescope.builtin").find_files({
        cwd = require("project.root").get(),
        find_command = args(all),
        prompt_title = all and "全部文件（仍排除 .git）" or "工程文件",
    })
end

local function grep_args()
    local result = { "--hidden" }
    for _, dir in ipairs(excluded) do
        vim.list_extend(result, { "--glob", "!**/" .. dir .. "/**" })
    end
    return result
end

function M.grep()
    require("telescope.builtin").live_grep({ cwd = require("project.root").get(), additional_args = grep_args })
end

function M.word()
    require("telescope.builtin").grep_string({ cwd = require("project.root").get(), additional_args = grep_args })
end

return M
