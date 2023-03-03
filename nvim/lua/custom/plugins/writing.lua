-- Tools and plugins for writing
return{
     -- Tools for LaTeX and markdown
  "lervag/vimtex",
  "junegunn/goyo.vim", -- distraction-free writing

  -- Obidian and Markdown stuff
  { "iamcco/markdown-preview.nvim",  run = function() vim.fn["mkdp#util#install"]() end },

  -- Obsidian inside nvim
  { "epwalsh/obsidian.nvim", 
    config = function()
        require("obsidian").setup {
            dir = "~/code/obsidian-secondBrain/",
            completion = {
              nvim_cmp = true,
            }
        }
    end,
  },

  "preservim/vim-markdown",
  "godlygeek/tabular",
}