{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix # The generated hardware file
    # ./disko.nix
  ];

  networking.hostName = "makedon";
  system.stateVersion = "25.11";

  ## Legacy BIOS boot: disk has no EFI System Partition, so override
  ## the UEFI systemd-boot default from modules/common.nix with GRUB.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    efiSupport = false;
    enableCryptodisk = true;
  };

  ## Trim SSD
  services.fstrim.enable = true;

  # Battery Stuff
  services.power-profiles-daemon.enable = false; # use tlp instead
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

      #Optional helps save long term battery health
      START_CHARGE_THRESH_BAT1 = 40; # 40 and bellow it starts to charge
      STOP_CHARGE_THRESH_BAT1 = 80; # 80 and above it stops charging

    };
  };

  ## Legion 5 ARH05H ships with the dGPU-only BIOS mode (no AMD iGPU exposed),
  ## so nouveau's lack of color management/gamma support shows as washed-out output.
  hardware.nvidia = {
    open = true; # Turing (RTX 20xx) is GSP-capable, open driver is the recommended default
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  ## The BOE NV156FHM-NX1 panel in this chassis only covers ~51% sRGB, so
  ## everything looks flat/washed out at the driver's neutral Digital
  ## Vibrance (0). nvidia-settings doesn't expose this control on Wayland,
  ## so set it directly via nvibrant on every login.
  systemd.user.services.nvidia-vibrance = {
    description = "Boost NVIDIA digital vibrance to compensate for the panel's narrow color gamut";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nvibrant}/bin/nvibrant 0 0 0 700";
    };
  };

  ## The ALC257 codec driving this laptop's speakers has no amp/DSP boost
  ## exposed on Linux (ALSA mixer already sits at 0dB max), so stock output
  ## is thin and quiet compared to Windows' Dolby Atmos tuning. Compensate
  ## in software: bass enhancer + upward compressor ("Boosting" mode, lifts
  ## quiet passages) + a safety limiter so neither of those clip.
  home-manager.users.benjamin = {
    services.easyeffects = {
      enable = true;
      preset = "legion-speakers";
      extraPresets.legion-speakers.output = {
        blocklist = [ ];
        plugins_order = [
          "bass_enhancer#0"
          "compressor#0"
          "limiter#0"
        ];
        "bass_enhancer#0" = {
          bypass = false;
          amount = 9.0;
          blend = -5.0;
          floor = 20.0;
          floor-active = true;
          harmonics = 8.5;
          scope = 120.0;
          input-gain = 0.0;
          output-gain = 0.0;
        };
        "compressor#0" = {
          bypass = false;
          mode = "Boosting";
          attack = 10.0;
          release = 100.0;
          release-threshold = -80.0;
          threshold = -24.0;
          ratio = 2.0;
          knee = -6.0;
          makeup = 0.0;
          boost-amount = 8.0;
          boost-threshold = -72.0;
          sidechain-listen = false;
          input-gain = 0.0;
          output-gain = 0.0;
        };
        "limiter#0" = {
          bypass = false;
          mode = "Herm Thin";
          lookahead = 5.0;
          attack = 5.0;
          release = 5.0;
          threshold = -1.0;
          gain-boost = true;
          sidechain-preamp = 0.0;
          stereo-link = 100.0;
          alr = false;
          input-gain = 10.0;
          output-gain = 0.0;
        };
      };
    };
  };

  #####################################
  ###      Host Configuration       ###
  #####################################
  cfg = {

    stylix = {
      theme = "booberry";
      fontsize = 14;
    };

    backup.borgmatic = {
      enable = true;
      directories = [ "/home/benjamin/Documents" ];
      repositories.borgbase.path = "ssh://u715075@u715075.your-storagebox.de:23/./repo";
    };

    notes = {
      obsidian.enable = true;
      supernote.enable = true;

    };

    development = {
      enable = true;

      zed.enable = true;
      freecad.enable = true;

      git.tuis.lazygit.enable = true;
      git.guis.gitte.enable = true;

      android.enable = true;

      embedded.platformio.enable = true;

      virtualization = {
        docker.enable = true;
        vm.enable = true;
      };

      agentic = {
        enable = true;
        pi-coding-agent.enable = true;
        claude-code.enable = true;

      };

      languages = {
        typst.enable = true;
        ccpp.enable = true;
        rust.enable = true;
      };

    };

    browser.qutebrowser.enable = true;
    browser.chromium.enable = true;
    browser.webapp = {
      homeassistant.enable = true;
      endel.enable = true;
    };

    desktop.hyprland.enable = true;

    office = {
      enable = true;
      libre-office.enable = true;
      marktext.enable = true;
      apostrophe.enable = false; # currently has a bug

    };

    uni.enable = true;

    communication = {
      signal.enable = true;
      matrix.enable = true;
      mumble.enable = true;
      mail.tuta.enable = true;
      mail.thunderbird.enable = true;
    };

    socials = {
      irc.enable = true;
      mastodon.enable = true;
    };

    multimedia = {
      enable = true;
      ebooks = {
        enable = true;
        koreader.enable = true;
      };
      eilmeldung.enable = true;
      newsflash.enable = true;
    };

    privacy.enable = true;
    privacy.tor.enable = true;

    downloaders = {
      enable = true;
    };
  };

}
