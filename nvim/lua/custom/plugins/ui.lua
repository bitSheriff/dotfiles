return{

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
                            action = 'Lazy',
                            key = 'a',
                        },
                        {
                            desc = ' dotfiles',
                            group = 'Number',
                            action = 'Telescope find_files',
                            key = 'd',
                        },
                    },
                    project = { enable = false, limit = 8, icon = '󰺛 ', label = 'bitSheriff', action = 'Telescope find_files cwd=' },
                    mru = { limit = 10, icon = '󰺛 ', label = 'bitSheriff',},
                    footer = {" 󱑽 ride on the synthwave 󱑽 "},
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
}