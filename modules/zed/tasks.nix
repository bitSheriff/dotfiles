{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
  ];

  home-manager.users.${username} = {
    programs.zed-editor = {
      userTasks = [ ];
    };
  };

}
