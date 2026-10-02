# Same layout as the current install (1G ESP, ext4 root, ~34G swap), but root
# and swap live inside one LUKS container, so a single passphrase at boot
# unlocks both and nothing but /boot is readable on a stolen laptop.
#
# NOT imported yet (see ./default.nix): applying it means wiping the disk and
# reinstalling, and it replaces the `fileSystems` / `swapDevices` entries in
# ./hardware-configuration.nix, which have to be removed at the same time.
{
  disko.devices = {
    disk = {
      # Main Drive
      system = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                # No key file: disko asks for the passphrase when formatting,
                # the initrd asks for it on every boot.
                settings = {
                  allowDiscards = true; # keep fstrim (services.fstrim) working
                };
                content = {
                  type = "lvm_pv";
                  vg = "delos";
                };
              };
            };
          };
        };
      };
    };

    lvm_vg = {
      delos = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "34G";
            content = {
              type = "swap";
              resumeDevice = true; # enable hibernation (encrypted ofc)
            };
          };
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
