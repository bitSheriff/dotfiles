{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ./nix.nix
    ./shell/zsh.nix
    ./neovim
    ./networking.nix
    ./kitty.nix
    ./ssh.nix
    ./appimage.nix
    ./privacy.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "de";

  # Hardware Support & Services
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.devmon.enable = true;
  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
  ];

  security.polkit.enable = true;
  security.sudo = {
    enable = true;
    # increase the sudo timeout, in mins
    extraConfig = ''
      Defaults timestamp_timeout=30
    '';
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # User Configuration
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  # Only things that should be available to every user/root.
  environment.systemPackages = with pkgs; [
    # terminal tools
    bash # needed only for scripting
    zsh # actual shell
    zsh-autosuggestions # suggest commands
    zsh-completions # complete commands
    zsh-syntax-highlighting
    kitty
    vim # just as a backup if everythin burns
    gum # bash library to build cli tools
    wget
    curl
    git
    htop
    btop # better htop
    zip
    unzip # for .zip
    rar
    unrar # for .rar
    gnupg
    eza # better `ls`
    zoxide # smarter `cd` command
    television # like fzf but more fancy
    tree # view direvtory structure
    mise # like Nix but on project basis (prob not needed anymore if NixOS runs everywhere)
    atuin # better shell history
    rsync # nobody uses scp anymore
    tldr # better help/man pages for cli programs
    findutils # sometimes you need the old find...
    fd # better find
    _1password-cli
    glow # render markdown in the console
    speedtest-cli # download speed meter

    # Services and Co
    pciutils
    usbutils
    xdg-utils
    networkmanagerapplet # contains nm-connection-editor for advanced wifi configuration
    xauth # needed to forward SSH and more

    # GUIs
    _1password-gui
    firefox
    ente-auth
    killall
    kdePackages.kate # simple text editor
    nemo # Cinnamon File Explorer
    nemo-preview
    nemo-fileroller
    libqalculate # calculator CLI
    qalculate-gtk # calculator GUI
  ];

  programs.zsh = {
    enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.bat = {
    enable = true;
    settings = {
      italic-text = "always";
      map-syntax = [
        "*.ino:C++"
        ".ignore:Git Ignore"
      ];
      pager = "less";
      paging = "never";
      theme = "TwoDark";
    };
  };

  environment.sessionVariables = {
    SOPS_AGE_KEY_FILE = "/home/${username}/.age/dotfiles.key";

    # FZF Config options
    FZF_DEFAULT_COMMAND = "fd";
    FZF_DEFAULT_OPTS = "--multi --preview 'bat --style=numbers --color=always {}'";
    FZF_ALT_C_COMMAND = "rg --sort-files --files --null 2> /dev/null | xargs -0 dirname | uniq";

  };

  services.envfs.enable = true;

  services.flatpak.enable = true;
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  xdg.mime.defaultApplications = {
    "application/pdf" = [ "org.pwmt.zathura.desktop" ];
  };

}
