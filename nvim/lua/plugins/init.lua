vim.cmd "packadd packer.nvim"

local plugins = {

  ["nvim-lua/plenary.nvim"] = { module = "plenary" },
  ["wbthomason/packer.nvim"] = {},
  ["NvChad/extensions"] = { module = { "telescope", "nvchad" } },

  ["NvChad/base46"] = {
    config = function()
      local ok, base46 = pcall(require, "base46")

      if ok then
        base46.load_theme()
      end
    end,
  },

  ["NvChad/ui"] = {
    after = "base46",
    config = function()
      require("plugins.configs.others").nvchad_ui()
    end,
  },

  ["NvChad/nvterm"] = {
    module = "nvterm",
    config = function()
      require "plugins.configs.nvterm"
    end,
  },

  ["kyazdani42/nvim-web-devicons"] = {
    after = 'ui',
    module = "nvim-web-devicons",
    config = function()
      require("plugins.configs.others").devicons()
    end,
  },

  ["lukas-reineke/indent-blankline.nvim"] = {
    opt = true,
    setup = function()
      require("core.lazy_load").on_file_open "indent-blankline.nvim"
    end,
    config = function()
      require("plugins.configs.others").blankline()
    end,
  },

  ["NvChad/nvim-colorizer.lua"] = {
    opt = true,
    setup = function()
      require("core.lazy_load").on_file_open "nvim-colorizer.lua"
    end,
    config = function()
      require("plugins.configs.others").colorizer()
    end,
  },

  ["nvim-treesitter/nvim-treesitter"] = {
    module = "nvim-treesitter",
    setup = function()
      require("core.lazy_load").on_file_open "nvim-treesitter"
    end,
    cmd = require("core.lazy_load").treesitter_cmds,
    run = ":TSUpdate",
    config = function()
      require "plugins.configs.treesitter"
    end,
  },

  -- git stuff
  ["lewis6991/gitsigns.nvim"] = {
    ft = "gitcommit",
    setup = function()
      require("core.lazy_load").gitsigns()
    end,
    config = function()
      require("plugins.configs.others").gitsigns()
    end,
  },

  -- lsp stuff

  ["williamboman/mason.nvim"] = {
    cmd = require("core.lazy_load").mason_cmds,
    config = function()
      require "plugins.configs.mason"
    end,
  },

  ["neovim/nvim-lspconfig"] = {
    opt = true,
    setup = function()
      require("core.lazy_load").on_file_open "nvim-lspconfig"
    end,
    config = function()
      require "plugins.configs.lspconfig"
    end,
  },

  -- load luasnips + cmp related in insert mode only

  ["rafamadriz/friendly-snippets"] = {
    module = "cmp_nvim_lsp",
    event = "InsertEnter",
  },

  ["hrsh7th/nvim-cmp"] = {
    after = "friendly-snippets",
    config = function()
      require "plugins.configs.cmp"
    end,
  },

  ["L3MON4D3/LuaSnip"] = {
    wants = "friendly-snippets",
    after = "nvim-cmp",
    config = function()
      require("plugins.configs.others").luasnip()
    end,
  },

  ["saadparwaiz1/cmp_luasnip"] = {
    after = "LuaSnip",
  },

  ["hrsh7th/cmp-nvim-lua"] = {
    after = "cmp_luasnip",
  },

  ["hrsh7th/cmp-nvim-lsp"] = {
    after = "cmp-nvim-lua",
  },

  ["hrsh7th/cmp-buffer"] = {
    after = "cmp-nvim-lsp",
  },

  ["hrsh7th/cmp-path"] = {
    after = "cmp-buffer",
  },

  -- misc plugins
  ["windwp/nvim-autopairs"] = {
    after = "nvim-cmp",
    config = function()
      require("plugins.configs.others").autopairs()
    end,
  },

  ["goolord/alpha-nvim"] = {
    after = "base46",
    disable = true,
    config = function()
      require "plugins.configs.alpha"
    end,
  },

  ["numToStr/Comment.nvim"] = {
    module = "Comment",
    keys = { "gc", "gb" },
    config = function()
      require("plugins.configs.others").comment()
    end,
  },

  -- file managing , picker etc
  ["kyazdani42/nvim-tree.lua"] = {
    ft = "alpha",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    config = function()
      require "plugins.configs.nvimtree"
    end,
  },

  ["nvim-telescope/telescope.nvim"] = {
    cmd = "Telescope",
    config = function()
      require "plugins.configs.telescope"
    end,
  },

  -- Only load whichkey after all the gui
  ["folke/which-key.nvim"] = {
    module = "which-key",
    config = function()
      require "plugins.configs.whichkey"
    end,
  },

  -- Start up page
  ["startup-nvim/startup.nvim"] = {
    requires = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
  config = function()
    require"startup".setup()
  end
  },

  -- Highlight TODO comments 
  ["folke/todo-comments.nvim"] = {
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      }
  end
  }, 

  -- Tabs
  ["romgrk/barbar.nvim"] = {
    requires = {"kyazdani42/nvim-web-devicons"},
  },
  
  -- Themes
  ["EdenEast/nightfox.nvim"] = {},
  ["folke/tokyonight.nvim"] = {},
  ["catppuccin/nvim"] = {},
  ["dracula/vim"] = {},

  -- Tools for Rust
  ["neovim/nvim-lspconfig"] = {},
  ["simrat39/rust-tools.nvim"] = {},
--  ["rust-lang/rust"] = {},

}
vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha

require("core.packer").run(plugins)
require("rust-tools").setup({})
require("catppuccin").setup({})


-- Set the Theme
vim.cmd[[colorscheme dracula]]
