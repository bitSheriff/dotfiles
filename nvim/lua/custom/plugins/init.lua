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

    -- new jump and search plugin
    {
      "folke/flash.nvim",
      event = "VeryLazy",
      ---@type Flash.Config
      opts = {},
      keys = {
        {
          "ö",
          mode = { "n", "x", "o" },
          function()
            -- default options: exact mode, multi window, all directions, with a backdrop
            require("flash").jump()
          end,
          desc = "Flash",
        },
        {
          "Ö",
          mode = { "n", "o", "x" },
          function()
            require("flash").treesitter()
          end,
          desc = "Flash Treesitter",
        },
        {
          "r",
          mode = "o",
          function()
            require("flash").remote()
          end,
          desc = "Remote Flash",
        },
      },
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
    },

    -- sticky scroll
    "nvim-treesitter/nvim-treesitter-context",

    { "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("indent_blankline").setup {
                    show_current_context = true,
                    show_current_context_start = true,
            }
        end,
    },

    -- peek to line before jumping
    {"nacro90/numb.nvim",
        config = function()
            require("numb").setup {}
        end,
    },

    -- undotree
    {"mbbill/undotree"},

    -- plugin to open file with sudo
    {"lambdalisue/suda.vim"},
}
