return{
        "nvim-neorg/neorg",
        build = ":Neorg sync-parsers",
        opts = {
            load = {
              ["core.completion"] = { config = { engine = "nvim-cmp", name = "[Norg]" } },
              ["core.integrations.nvim-cmp"] = {},
              ["core.concealer"] = { config = { icon_preset = "diamond" } },
              ["core.export"] = {},
              ["core.journal"] = {},
              ["core.keybinds"] = {
                -- https://github.com/nvim-neorg/neorg/blob/main/lua/neorg/modules/core/keybinds/keybinds.lua
                config = {
                  default_keybinds = true,
                  neorg_leader = "<Leader><Leader>",
                },
                ["core.concealer"] = {}, -- Adds pretty icons to your documents
                ["core.dirman"] = { -- Manages Neorg workspaces
                    config = {
                        workspaces = {
                            notes = "~/neorg",
                        },
                    },
                },
            },
        },
    },
    dependencies = { { "nvim-lua/plenary.nvim" } },
}
