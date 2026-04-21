{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:
let

  # TU VPN
  # needed for some academic services
  tuvpn = pkgs.writeShellScriptBin "tuvpn" ''
    EMAIL=$(cat "${config.home-manager.users.benjamin.sops.secrets."uni/email".path}")
    PASS=$(cat "${config.home-manager.users.benjamin.sops.secrets."uni/password".path}")
    OTP_SECRET=$(cat "${config.home-manager.users.benjamin.sops.secrets."uni/otp_secret".path}")
    AUTHGROUP=$(${pkgs.gum}/bin/gum choose "1_TU_getunnelt" "2_Alles_getunnelt")

    # Generate the 2FA code
    OTP_CODE=$(${pkgs.oath-toolkit}/bin/oathtool --totp -b "$OTP_SECRET")

    echo "Connecting to TU Wien VPN..."

    (echo "$PASS"; echo "$OTP_CODE") | sudo ${pkgs.openconnect}/bin/openconnect \
      --useragent "AnyConnect OpenConnect" \
      --no-external-auth \
      --user "$EMAIL" \--form-entry="main:secondary_password=$OTP_CODE" \
      --authgroup="$AUTHGROUP" \
      --passwd-on-stdin \
      vpn.tuwien.ac.at
  '';

in
{
  imports = [
    ../modules/zathura.nix
  ];

  environment.systemPackages = with pkgs; [
    anki
    thunderbird
    typst
    typesetter # minimal typst editor
    # octave # free alternative to MATLAB (but why not use python then ...)
    jupyter # python jupyter notebook
    # wireshark-qt # network analyzer
    gum # needed for cli inputs
    openconnect # needed for the University VPN
    oath-toolkit # generate 2FA codes from secret
    blanket # background ambient soundscapes for concentration

    # Own Scripts
    tuvpn
  ];

  home-manager.users.benjamin.sops = lib.mkIf (lib.elem "benjamin" activeUsers) {
    secrets = {
      "uni/email" = {
        key = "tiss/email";
        sopsFile = ../encrypted/uni.yaml;
      };

      "uni/password" = {
        key = "tiss/password";
        sopsFile = ../encrypted/uni.yaml;
      };

      "uni/otp_secret" = {
        key = "tiss/otp_secret";
        sopsFile = ../encrypted/uni.yaml;
      };
    };
  };

}
