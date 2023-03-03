local opt = vim.opt
local g = vim.g

opt.relativenumber = true

opt.clipboard = "unnamedplus"

-- Scrolling
opt.so = 999 -- keep cursor in the middle


-- Set the Theme
vim.cmd[[colorscheme dracula]]