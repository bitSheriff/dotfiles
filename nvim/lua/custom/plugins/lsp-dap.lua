local dap = require('dap')

-- setup cpptools adapter
dap.adapters.cpptools = {
  type = 'executable',
  name = "cpptools",
  command = vim.fn.stdpath('data') .. '/mason/bin/OpenDebugAD7',
  args = {},
  attach = {
    pidProperty = "processId",
    pidSelect = "ask"
  },
}


-- this configuration should start cpptools and the debug the executable main in the current directory when executing :DapContinue
dap.configurations.cpp = {
  {
    name = "Launch",
    type = "cpptools",
    request = "launch",
    program = '${workspaceFolder}/main',
    cwd = '${workspaceFolder}',
    stopOnEntry = true,
    args = {},
    runInTerminal = false,
  },
}

dap.configurations.c = dap.configurations.cpp

-- Tools and plugins for writing
return {
  -- Tools for Rust
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    config = function()
      require("rust-tools").setup {}
    end,
  },

  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end
  },

  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function(_, opts)
      local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(path)
    end,
  },
}
