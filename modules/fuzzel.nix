{
  config,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username}.programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        dpi-aware = "no";
        width = 30;
        font = "Comic Mono:weight=bold:size=14";
        line-height = 20;
        fields = "name,generic,comment,categories,filename,keywords";
        terminal = "kitty -e";
        prompt = "❯   ";
        layer = "overlay";
      };
      colors = {
        # dracula color scheme
        background = "282a36dd";
        text = "f8f8f2ff";
        match = "8be9fdff";
        selection-match = "8be9fdff";
        selection = "44475add";
        selection-text = "f8f8f2ff";
        border = "bd93f9ff";
      };

    };

  };
}
