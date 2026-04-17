{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../modules/zathura.nix
  ];

  environment.systemPackages = with pkgs; [
    anki
    thunderbird
    typst
    typesetter # minimal typst editor
    # octave # free alternative to MATLAB (but my not use python then ...)
    jupyter # python jupyter notebook
    # wireshark-qt # network analyzer
    openconnect # needed for the University VPN
  ];

  home-manager.users.${username}.sops = {
    secrets = {
      "uni/email" = {
        key = "tiss/email";
        sopsFile = ../encrypted/uni.yaml;
      };

      "uni/password" = {
        key = "tiss/password";
        sopsFile = ../encrypted/uni.yaml;
      };
    };
  };

}
