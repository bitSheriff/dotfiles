{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.git = {
      enable = true;
      lfs.enable = true;

      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaKM4Dwfago4s/0Ap9hFHZMmqoly90mS/3rEl+7prJx";
        signByDefault = true;
      };

      settings = {
        user = {
          name = "bitSheriff";
          email = "root@bitsheriff.dev";
        };
        alias = {
          lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          lgall = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --reflog";
          winner = "shortlog -sn";
          pfusch = "push -f --all";
          backup = "! git push --all backup && git push --tags backup";
          ignore = "update-index --assume-unchanged";
          no-ignore = "update-index --no-assume-unchanged";
          sync = "! git pull && git push";
          dangling = "! git fsck --lost-found | grep \"^dangling commit\" | sed \"s/^dangling commit //g\" | xargs git show -s --oneline";
          cloner = "clone --recurse-submodules -j8";
          pushall = "!git remote | xargs -L1 git push --all";
          graph = "!serie";
          today = "!git-today";
          mrg = "merge --no-commit";
        };

        core = {
          editor = "nvim";
          autocrlf = "input";
          compression = 9;
          whitespace = "trailing-space";
        };
        merge = {
          tool = "meld";
          conflictStyle = "zdiff3";
        };
        diff = {
          tool = "meld";
          algorithm = "histogram";
        };
        gpg = {
          format = "ssh";
        };
        "gpg \"ssh\"" = {
          program = "op-ssh-sign";
        };
        init = {
          defaultBranch = "main";
        };
        push = {
          autoSetupRemote = true;
          default = "current";
          followTags = true;
        };
        pull = {
          rebase = true;
        };
        rebase = {
          autoStash = true;
        };
        submodule = {
          recurse = true;
        };
        help = {
          autocorrect = "prompt";
        };
        advice = {
          addIgnoredFile = false;
        };
        http = {
          postBuffer = 157286400;
        };
        branch = {
          sort = "-committerdate";
        };
        column = {
          ui = "auto";
        };
        tag = {
          sort = "-version:refname";
        };
        maintenance = {
          auto = true;
          strategy = "incremental";
        };
        status = {
          branch = true;
        };
        rerere = {
          enabled = true;
          autoUpdate = true;
        };
      };
    };

    # Delta: A better diff tool
    programs.delta = {
      enable = true;
      options = {
        navigate = true;
        dark = true;
        line-numbers = true;
        hyperlinks = true;
        side-by-side = true;
      };
    };
  };

}
