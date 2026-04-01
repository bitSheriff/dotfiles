{ config, pkgs, ... }:

{
  imports = [
  ];

  home-manager.users.benjamin = {
    programs.zed-editor = {
      userTasks = [ ];
    };
  };

}
