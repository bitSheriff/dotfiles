-- Tools and plugins for writing
return{
     -- Tools for LaTeX and markdown
  "lervag/vimtex",
  "junegunn/goyo.vim", -- distraction-free writing

  -- Obidian and Markdown stuff
  { "iamcco/markdown-preview.nvim",  run = function() vim.fn["mkdp#util#install"]() end },

  "epwalsh/obsidian.nvim",
  "preservim/vim-markdown",
  "godlygeek/tabular",
}