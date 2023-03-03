-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- load all the snippets
require("custom.plugins.snippets.all")

return {


    "folke/which-key.nvim",

    { "folke/todo-comments.nvim",
        dependencies = {"nvim-lua/plenary.nvim"},
        config = function()
          require("todo-comments").setup {}
        end,
    },

    -- hot faster inside code
    { "phaazon/hop.nvim",
        config = function()
            require("hop").setup {}
        end,
    },

    -- nvim start up page
    { "glepnir/dashboard-nvim",
        event = 'VimEnter',
        theme = 'hyper',
        config = function()
            require("dashboard").setup {}
        end,
    },

    -- Tabs
    { "akinsho/nvim-bufferline.lua",
        config = function()
            require("bufferline").setup {}
        end,
    },

    -- view hex colors_name
    { "NvChad/nvim-colorizer.lua",
        config = function()
            require("colorizer").setup {}
        end,
    },
}
