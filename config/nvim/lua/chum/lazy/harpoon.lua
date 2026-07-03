return {
        "ThePrimeagen/harpoon",
        config = function()
            local mark = require("harpoon.mark")
            local ui = require("harpoon.ui")

            vim.keymap.set("n", "<leader>a", function() mark.add_file() end)
            vim.keymap.set("n", "<C-e>", function() ui.toggle_quick_menu() end)
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    }
