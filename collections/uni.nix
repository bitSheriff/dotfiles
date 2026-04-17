{
  config,
  pkgs,
  username,
  ...
}:
let

  # TU VPN
  # needed for some academic serices
  tuvpn = pkgs.writeShellScriptBin "tuvpn" ''
    EMAIL=$(cat "${config.home-manager.users.${username}.sops.secrets."uni/email".path}")
    PASS=$(cat "${config.home-manager.users.${username}.sops.secrets."uni/password".path}")
    OTP_SECRET=$(cat "${config.home-manager.users.${username}.sops.secrets."uni/otp_secret".path}")

    # Generate the code
    OTP_CODE=$(${pkgs.oath-toolkit}/bin/oathtool --totp -b "$OTP_SECRET")

    echo "Connecting to TU Wien VPN..."

    (echo "$PASS"; echo "$OTP_CODE") | sudo ${pkgs.openconnect}/bin/openconnect \
      --useragent "AnyConnect OpenConnect" \
      --no-external-auth \
      --user "$EMAIL" \
      --authgroup="1_TU_getunnelt" \
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
    # octave # free alternative to MATLAB (but my not use python then ...)
    jupyter # python jupyter notebook
    # wireshark-qt # network analyzer
    openconnect # needed for the University VPN
    oath-toolkit # generate 2FA codes from secret

    # Own Scripts
    tuvpn
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

      "uni/otp_secret" = {
        key = "tiss/otp_secret";
        sopsFile = ../encrypted/uni.yaml;
      };
    };
  };

}
