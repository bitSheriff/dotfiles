return {

    -- nvim start up page
    {
        "glepnir/dashboard-nvim",
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
                    project = {
                        enable = false,
                        limit = 8,
                        icon = '󰺛 ',
                        label = 'bitSheriff',
                        action = 'Telescope find_files cwd='
                    },
                    mru = { limit = 10, icon = '󰺛 ', label = 'bitSheriff', },
                    footer = { " 󱑽 ride on the synthwave 󱑽 " },
                },
            }
        end,
    },

    -- Tabs
    {
        "akinsho/nvim-bufferline.lua",
        config = function()
            require("bufferline").setup {}
        end,
    },

    -- view hex colors_name
    {
        "NvChad/nvim-colorizer.lua",
        config = function()
            require("colorizer").setup {}
        end,
    },


    -- lazy.nvim
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            -- add any options here
        },
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            "MunifTanjim/nui.nvim",
            -- OPTIONAL:
            --   `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            "rcarriga/nvim-notify",
        },
        config = function()
            require("noice").setup({
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = true,         -- use a classic bottom cmdline for search
                    command_palette = true,       -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false,           -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = false,       -- add a border to hover docs and signature help
                },
            })
        end
    }
}
