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
        config = function()
            require("dashboard").setup {
                theme = 'hyper',
                config = {
                    week_header = {
                        enable = true,
                    },
                    shortcut = {
                        { desc = ' Update', group = '@property', action = 'Lazy update', key = 'u' },
                        {
                            icon = ' ',
                            icon_hl = '@variable',
                            desc = 'Files',
                            group = 'Label',
                            action = 'Telescope find_files',
                            key = 'f',
                        },
                        {
                            desc = ' Apps',
                            group = 'DiagnosticHint',
                            action = 'Telescope app',
                            key = 'a',
                        },
                        {
                            desc = ' dotfiles',
                            group = 'Number',
                            action = 'Telescope dotfiles',
                            key = 'd',
                        },
                    },
                    project = { enable = false, limit = 8, icon = '󰺛 ', label = 'bitSheriff', action = 'Telescope find_files cwd=' },
                    mru = { limit = 10, icon = '󰺛 ', label = 'bitSheriff',},
                    footer = {enable = true ,label = 'riding on the synthwave'},
                },
            }
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

    -- git stuff
    "kdheepak/lazygit.nvim",

    -- better terminal
    { "akinsho/toggleterm.nvim", version = "*", config = true},

    -- sourrund selection
    "tpope/vim-surround",
    
    -- zen mode
    {   "folke/zen-mode.nvim",
        config = function()
            require("zen-mode").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
    }
        end,
    }
}
