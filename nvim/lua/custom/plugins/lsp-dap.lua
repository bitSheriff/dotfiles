-- Tools and plugins for writing
return{
  -- Tools for Rust
  { "simrat39/rust-tools.nvim",
    ft="rust",
    config = function()
        require("rust-tools").setup {}
    end,
  },

  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function ()
      vim.g.rustfmt_autosave = 1     
    end
  }
}
