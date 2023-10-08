local opt = vim.opt
local g = vim.g

-- line numbers
opt.relativenumber = true

opt.clipboard = "unnamedplus"

-- Scrolling
opt.so = 999 -- keep cursor in the middle

-- Indenting
opt.expandtab = true
opt.shiftwidth = 4
opt.smartindent = true
opt.autoindent = true
opt.tabstop = 4
opt.softtabstop = 4

-- Set the Theme
vim.cmd [[colorscheme dracula]]


vim.cmd [[set spelllang=en,de]]

-- set soft wrapping as default
require('wrapping').soft_wrap_mode()
