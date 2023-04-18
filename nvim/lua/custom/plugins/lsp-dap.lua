-- Tools and plugins for writing
return{
  -- Tools for Rust
  { "simrat39/rust-tools.nvim",
    config = function()
        require("rust-tools").setup {}
    end,
  }
}
