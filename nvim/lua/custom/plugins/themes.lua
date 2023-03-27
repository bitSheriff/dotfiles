return{
    "EdenEast/nightfox.nvim",
    "folke/tokyonight.nvim",
    { "catppuccin/nvim",name = "catppuccin" },
    { "LunarVim/synthwave84.nvim",
        config = function()
            require("synthwave84").setup {
                  glow = {
                    error_msg = true,
                    type2 = true,
                    func = true,
                    keyword = true,
                    operator = true,
                    buffer_current_target = true,
                    buffer_visible_target = true,
                    buffer_inactive_target = true,
                }
            }
        end,
    },

    "rebelot/kanagawa.nvim",
    "maxmx03/dracula.nvim",
}

-- theme will be set in the after/plugin/defaults.lua file
