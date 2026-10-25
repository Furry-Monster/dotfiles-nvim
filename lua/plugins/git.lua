return {
    {
        "nvim-mini/mini.diff",
        version = "*",
        cmd = "Git",
        event = { "BufReadPost", "BufNewFile" },
        config = function() require("config.git").setup() end,
    },
}
