local present, treesitter = pcall(require, "nvim-treesitter.configs")

if not present then
  return
end

require("base46").load_highlight "syntax"
require("base46").load_highlight "treesitter"

local options = {
  ensure_installed = {
    "lua",
    "c",
    "cpp",
    "rust",
    "python",
    "markdown",
    "markdown_inline",
    "java",
  },
  highlight = {
    enable = true,
    use_languagetree = true,
    disable = { "latex" },
  },
}

-- check for any override
options = require("core.utils").load_override(options, "nvim-treesitter/nvim-treesitter")

treesitter.setup(options)
