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
map("n", "<leader>sr", require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
map("n", "<leader>ss", "<cmd>Telescope live_grep<cr>", { silent = true, desc = "Search in the current file" })

-- toggle the build in file explorer
map("n", "<leader>n", "<cmd>Neotree toggle<cr>", { silent = true, desc = "Open [N]eotree" })

-- Redo
map("n", "<S>u", "<cmd>redo<cr>", { silent = true, desc = "Redo" })

-- Move lines up and down in normal mode
map("n", "<A-Down>", "<cmd> :m . +1 <cr>")
map("n", "<A-Up>", "<cmd> :m . -2 <cr>")

-- Tabs
map("n", "<TAB>", "<cmd> BufferLineCycleNext <cr>", { desc = "goto next buffer" })
map("n", "<S-TAB>", "<cmd> BufferLineCyclePrev <cr>", { desc = "goto prev buffer" })

-- lazy stuff
map("n", "<leader>lg", "<cmd>LazyGit <cr>", { desc = "call [L]azy[G]it" })
map("n", "<leader>ls", "<cmd>Lazy sync <cr>", { desc = "call [L]azy [S]ync" })
map("n", "<leader>lu", "<cmd>Lazy update <cr>", { desc = "call [L]azy [U]pdate" })

-- terminal
map("n", "<leader>th", "<cmd> ToggleTerm size=10 direction=horizontal <cr>", { desc = " [T]erminal [H]orizontal Toggle" })
map("n", "<leader>tv", "<cmd> ToggleTerm size=60 direction=vertical <cr>", { desc = " [T]erminal [V]ertical Toggle" })
map("n", "<leader>tf", "<cmd> ToggleTerm size=60 direction=float <cr>", { desc = " [T]erminal [F]loat Toggle" })

-- Obsidian Workspace
map("n", "<leader>os", "<cmd> ObsidianQuickSwitch <cr>", { desc = "[O]bsidian Quick [S]witch" })

-- actions
map("n", "<leader>af", "gg=G", { desc = "[A]ction code [f]ormat while file" })
map("n", "<leader>aF", "<cmd> Format <cr>", { desc = "[A]ction code [F]ormat while file with LSP" })
map("n", "<leader>az", "<cmd> ZenMode <cr>", { desc = "[A]ction toggle [z]en mode" })
map("n", "<leader>ar", "<cmd> lua vim.lsp.buf.rename() <cr>", { desc = "[A]ction [r]ename symbol" })
map("n", "<leader>ac", "<cmd> lua vim.lsp.buf.code_action() <cr>", { desc = "[A]ction [c]ode" })
map("n", "<leader>as", "<cmd> set spell! <cr>", { desc = "[A]ction toggle [s]pell checker" })
map("n", "<leader>au", "<cmd> UndotreeToggle <cr>", { desc = "[A]ction toggle [u]ndotree" })
map("n", "<leader>aw", "<cmd> SudaWrite <cr>", { desc = "[A]ction [w]rite file with sudo" })

-- builds
map("n", "<leader>bm", "<cmd> MarkdownPreview <cr>", { desc = "[b]uild [m]arkdown" })
map("n", "<leader>bl", "<cmd> VimtexCompile <cr>", { desc = "[b]uild [l]atex" })
map("n", "<leader>bca", "<cmd> make all <cr>", { desc = "[b]uild [c] make [a]ll" })
map("n", "<leader>bcc", "<cmd> make clean <cr>", { desc = "[b]uild [c] make [c]lean" })
map("n", "<leader>bcd", "<cmd> make doc <cr>", { desc = "[b]uild [c] make [d]oc" })



-- debugging

map("n", "<leader>dr", "<cmd> DapContinue <cr>", { desc = "[D]ebug [R]un / Continue" })
map("n", "<leader>db", "<cmd> DapToggleBreakpoint <cr>", { desc = "[D]ebug [B]reakpoint" })
map("n", "<leader>d,", "<cmd> DapStepInto <cr>", { desc = "[D]ebug Step Into" })
map("n", "<leader>d-", "<cmd> DapStepOver <cr>", { desc = "[D]ebug Step Over" })
map("n", "<leader>d_", "<cmd> DapStepOut <cr>", { desc = "[D]ebug Step Out" })

-- windows (=> panes)
map("n", "<C-w>N", "<cmd> vnew <cr>", { desc = "[W]indow create [N]ew vertical window" })
