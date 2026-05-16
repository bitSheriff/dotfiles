{ config, pkgs, ... }:
let
  notesDir = "~/notes";
in
{
  programs.nvf.settings.vim = {
    binds.whichKey.register."<leader>n" = "+Notes";
    notes.obsidian = {
      enable = true;
      setupOpts = {
        frontmatter.enabled = false; # can fuck up my metadata
        workspaces = [
          {
            name = "notes";
            path = notesDir;
          }
        ];

        daily_notes = {
          enabled = true;
          folder = "Journal/Daily";
          date_format = "YYYY-MM-DD";
        };

        link = {
          style = "wiki";
          format = "absolute";
          auto_update = false;
        };
      };
    };
  };
}
