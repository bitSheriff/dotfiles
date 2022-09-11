local present, masonlspconfig = pcall(require, "mason-lspconfig")

if not present then
  return
end
local options = {
  ensure_installed = { "lua-language-server",
                       "python-lsp-server",
                       "rust-analyzer",
                       "jdtls"}, -- not an option from mason.nvim
}


masonlspconfig.setup(options)
