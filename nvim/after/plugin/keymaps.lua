local function map(mode, lhs, rhs, opts)
    local keys = require("lazy.core.handler").handlers.keys
    ---@cast keys LazyKeysHandler
    -- do not create the keymap if a lazy keys handler exists
    if not keys.active[keys.parse({ lhs, mode = mode }).id] then
      opts = opts or {}
      opts.silent = opts.silent ~= false
      vim.keymap.set(mode, lhs, rhs, opts)
    end
  end
  
  -- better up/down
  map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
  map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
  map("n", "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
  map("n", "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

  -- searching 
  map("n", "<leader>sr",    require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
  map("n", "<leader>ss",    "<cmd>Telescope live_grep<cr>", { silent = true, desc = "Search in the current file" })

  -- hop anywhere in the code
  map("n", "<leader>sb",    "<cmd>HopAnywhere<cr>", { silent = true, desc = "Hop anywhere in the current file" })

  -- toggle the build in file explorer
  map("n", "<leader>n",    "<cmd>Neotree toggle<cr>", { silent = true, desc = "Open [N]eotree" })

  -- Redo
  map("n", "<S>u",      "<cmd>redo<cr>", { silent = true, desc = "Redo" })

  -- Move lines up and down in normal mode
  map("n", "<A-Down>",  "<cmd> :m . +1 <cr>")
  map("n", "<A-Up>",    "<cmd> :m . -2 <cr>")

  -- Tabs
  map("n", "<TAB>",     "<cmd> BufferLineCycleNext <cr>", {desc = "goto next buffer"})
  map("n", "<S-TAB>",   "<cmd> BufferLineCyclePrev <cr>", {desc = "goto prev buffer"})

  -- lazygit
  map("n", "<leader>lg",  "<cmd>LazyGit <cr>", {desc = "call [L]azy[G]it"})

 -- terminal
 map("n", "<leader>th", "<cmd> ToggleTerm size=10 direction=horizontal <cr>", {desc = " [T]erminal [H]orizontal Toggle"})
 map("n", "<leader>tv", "<cmd> ToggleTerm size=60 direction=vertical <cr>", {desc = " [T]erminal [V]ertical Toggle"})
 map("n", "<leader>tf", "<cmd> ToggleTerm size=60 direction=float <cr>", {desc = " [T]erminal [F]loat Toggle"})

-- Obsidian Workspace
map("n", "<leader>os", "<cmd> ObsidianQuickSwitch <cr>", {desc = "[O]bsidian Quick [S]witch"})
