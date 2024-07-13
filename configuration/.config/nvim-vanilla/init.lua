-- ========================================================================== --
-- ==                           EDITOR SETTINGS                            == --
-- ========================================================================== --

local set = vim.opt

set.hidden = true
set.swapfile = false
set.backup = false
set.hlsearch = false
set.wrap = false
set.mouse = "a"
set.termguicolors = true
set.scrolloff = 2
set.relativenumber = true

set.tabstop = 2
set.shiftwidth = 2
set.softtabstop = 2
set.expandtab = true

vim.g.netrw_winsize = 30
vim.g.netrw_banner = 0

vim.cmd([[
  syntax enable
  colorscheme default
]])

-- ========================================================================== --
-- ==                             KEY MAPPINGS                             == --
-- ========================================================================== --

-- Space as leader key
vim.g.mapleader = " "

local bind = vim.keymap.set
local remap = { remap = true }

-- Enter command mode
bind("n", "<CR>", ":")

-- Escape to normal mode
bind("", "<C-L>", "<Esc>")
bind("i", "<C-L>", "<Esc>")
bind("t", "<C-L>", "<C-\\><C-n>")

-- Shortcuts
bind("", "<Leader>h", "^")
bind("", "<Leader>l", "g_")
bind("", "<C-u>", "<C-u>M")
bind("", "<C-d>", "<C-d>M")
bind("n", "<Leader>e", "%", remap)
bind("v", "<Leader>e", "%", remap)
bind("n", "<Leader>a", "ggVG")

-- Basic clipboard interaction
if vim.fn.has("clipboard") == 1 then
	bind("", "cp", '"+y')
	bind("", "cv", '"+p')
end

-- Moving lines and preserving indentation
bind("n", "<C-j>", ":move .+1<CR>==")
bind("n", "<C-k>", ":move .-2<CR>==")
bind("v", "<C-j>", ":move '>+1<CR>gv=gv")
bind("v", "<C-k>", ":move '<-2<CR>gv=gv")

-- Commands
bind("n", "<Leader>w", ":write<CR>")
bind("n", "<C-q>", ":quitall<CR>")
bind("n", "<C-Q>", ":quitall!<CR>")
bind("n", "<Leader>bq", ":bdelete<CR>")
bind("n", "<Leader>bl", ":buffer #<CR>")
bind("n", "<Leader>bb", ":buffers<CR>:buffer<Space>")
bind("n", "<Leader>dd", ":Lexplore %:p:h<CR>")
bind("n", "<Leader>da", ":Lexplore<CR>")

local function netrw_mapping()
	local bufmap = function(lhs, rhs)
		local opts = { buffer = true, remap = true }
		vim.keymap.set("n", lhs, rhs, opts)
	end

	-- close window
	bufmap("<leader>dd", ":Lexplore<CR>")
	bufmap("<leader>da", ":Lexplore<CR>")

	-- Better navigation
	bufmap("H", "u")
	bufmap("h", "-^")
	bufmap("l", "<CR>")
	bufmap("L", "<CR>:Lexplore<CR>")

	-- Toggle dotfiles
	bufmap(".", "gh")
end

local user_cmds = vim.api.nvim_create_augroup("user_cmds", { clear = true })
vim.api.nvim_create_autocmd("filetype", {
	pattern = "netrw",
	group = user_cmds,
	desc = "Keybindings for netrw",
	callback = netrw_mapping,
})
