{ config, pkgs, ... }:
{
  programs.nvf = {

    # view keympas on the go
    settings.vim.binds.whichKey.enable = true;

    settings.vim.keymaps = [
      {
        key = "<leader>wq";
        mode = [ "n" ];
        action = ":wq<CR>";
        silent = true;
        desc = "Save file and quit";
      }
      {
        key = "<leader>n";
        mode = [ "n" ];
        action = ":NvimTreeToggle<CR>";
        silent = true;
        desc = "Toggle the file explorer on the side";
      }
      {
        key = "<c-q>";
        mode = [ "n" ];
        action = ":qa<CR>";
        silent = true;
        desc = "Exit";
      }
      {
        key = "<c-s>";
        mode = [ "n" ];
        action = ":w<CR>";
        silent = true;
        desc = "Save current file";
      }
      {
        key = "<c-a>";
        mode = [ "n" ];
        action = "ggVG";
        silent = true;
        desc = "Select All";
      }
      {
        key = "<Tab>";
        mode = [ "n" ];
        action = ":BufferLineCycleNext<CR>";
        silent = true;
        desc = "Next buffer";
      }
      {
        key = "<S-Tab>";
        mode = [ "n" ];
        action = ":BufferLineCyclePrev<CR>";
        silent = true;
        desc = "Previous buffer";
      }
      {
        key = "<leader>f";
        mode = [ "n" ];
        action = "function() require('flash').jump() end";
        silent = true;
        desc = "Flash";
      }
      {
        key = "<leader>hl";
        mode = [ "n" ];
        action = ":LazyGit<CR>";
        silent = true;
        desc = "Open LazyGit";
      }
      {
        key = "<leader>tt";
        mode = "n";
        lua = true;
        silent = true;
        desc = "Smart toggle/create Markdown Todo";
        action = ''
          function()
            local line = vim.api.nvim_get_current_line()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))

            -- Case 1: Line is completely empty or just whitespace
            if line:match("^%s*$") then
              vim.api.nvim_set_current_line(line .. "- [ ] ")
              -- Move cursor to the end of the newly inserted string
              vim.api.nvim_win_set_cursor(0, {row, #line + 6})
              -- Enter insert mode
              vim.cmd("startinsert!")

            -- Case 2: Line contains an incomplete todo -> Mark as Done
            elseif line:match("%-%s%[%s%]") then
              -- Note: gsub is wrapped in () to force a single return value
              vim.api.nvim_set_current_line((line:gsub("%-%s%[%s%]", "- [x]", 1)))

            -- Case 3: Line contains a done todo -> Mark as Undone
            elseif line:match("%-%s%[[xX]%]") then
              vim.api.nvim_set_current_line((line:gsub("%-%s%[[xX]%]", "- [ ]", 1)))

            -- Case 4: Normal text line -> Prepend a todo box, keeping indentation
            else
              local indent, rest = line:match("^(%s*)(.*)$")
              vim.api.nvim_set_current_line(indent .. "- [ ] " .. rest)
            end
          end
        '';
      }

      ## Notes ##
      {
        mode = "n";
        key = "<leader>nn";
        action = "<cmd>Obsidian new";
        desc = "Create new note";
      }
      {
        mode = "n";
        key = "<leader>nd";
        action = "<cmd>Obsidian today<CR>";
        desc = "Open daily notes";
      }
      {
        mode = "n";
        key = "<leader>nf";
        action = "<cmd>Obsidian quick_switch<CR>";
        desc = "Toggle concealer";
      }
    ];
  };
}
