return {
    {
        "zbirenbaum/copilot.lua",
        enabled = require("config.settings").ai.copilot,
        lazy = true,
        -- No event/cmd trigger, and no server auto-download.
        config = function() require("config.copilot").start() end,
    },
}
